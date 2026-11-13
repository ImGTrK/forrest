# Conversor mínimo .ase/.aseprite -> PNG (tira horizontal de frames, capas visibles compuestas).
import struct, zlib, sys, os

def png_write(path, w, h, rgba):
    raw = b''.join(b'\x00' + bytes(rgba[y*w*4:(y+1)*w*4]) for y in range(h))
    def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
                + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))

def convert(src, dst):
    d = open(src, 'rb').read()
    _, magic, nframes, W, H, depth, flags, speed = struct.unpack_from('<IHHHHHIH', d, 0)
    assert magic == 0xA5E0, 'no es .ase'
    transparent_idx = d[28]
    pos = 128
    layers, palette, frames, durations = [], [(0,0,0,0)]*256, [], []
    for fi in range(nframes):
        fsize, fmagic, old_chunks, dur = struct.unpack_from('<IHHH', d, pos)
        new_chunks = struct.unpack_from('<I', d, pos + 12)[0]
        nchunks = new_chunks or old_chunks
        p = pos + 16
        cels = []
        for _ in range(nchunks):
            csize, ctype = struct.unpack_from('<IH', d, p)
            body = d[p+6:p+csize]
            if ctype == 0x2004:  # layer
                lflags, ltype, child, _, _, blend, opacity = struct.unpack_from('<HHHHHHB', body, 0)
                layers.append({'visible': bool(lflags & 1), 'type': ltype, 'opacity': opacity})
            elif ctype == 0x2019:  # palette
                size, first, last = struct.unpack_from('<III', body, 0)
                q = 20
                for i in range(first, last + 1):
                    eflags, r, g, b, a = struct.unpack_from('<HBBBB', body, q); q += 6
                    if eflags & 1:
                        n = struct.unpack_from('<H', body, q)[0]; q += 2 + n
                    palette[i] = (r, g, b, a)
            elif ctype == 0x2005:  # cel
                li, x, y, op, ctype2 = struct.unpack_from('<HhhBH', body, 0)
                q = 16
                if ctype2 in (0, 2):
                    w, h = struct.unpack_from('<HH', body, q); q += 4
                    px = body[q:] if ctype2 == 0 else zlib.decompress(body[q:])
                    cels.append((li, x, y, op, w, h, px))
                elif ctype2 == 1:  # linked cel
                    link = struct.unpack_from('<H', body, q)[0]
                    for c in frames[link][0]:
                        if c[0] == li: cels.append(c)
            p += csize
        frames.append((cels, dur))
        pos += fsize
    bpp = depth // 8
    out = bytearray(W * H * 4 * nframes)
    stride = W * nframes * 4
    for fi, (cels, dur) in enumerate(frames):
        for (li, x, y, op, w, h, px) in sorted(cels, key=lambda c: c[0]):
            L = layers[li] if li < len(layers) else {'visible': True, 'opacity': 255, 'type': 0}
            if not L['visible'] or L['type'] != 0: continue
            for j in range(h):
                for i in range(w):
                    k = (j * w + i) * bpp
                    if bpp == 4: r, g, b, a = px[k:k+4]
                    elif bpp == 2: v, a = px[k], px[k+1]; r = g = b = v
                    else:
                        idx = px[k]
                        if idx == transparent_idx: continue
                        r, g, b, a = palette[idx]
                    a = a * op * L['opacity'] // (255 * 255)
                    X, Y = x + i, y + j
                    if a == 0 or not (0 <= X < W and 0 <= Y < H): continue
                    o = Y * stride + (fi * W + X) * 4
                    if a == 255: out[o:o+4] = bytes((r, g, b, 255))
                    else:  # alpha over
                        da = out[o+3] / 255; sa = a / 255; na = sa + da * (1 - sa)
                        for c, s in enumerate((r, g, b)):
                            out[o+c] = int((s * sa + out[o+c] * da * (1 - sa)) / na) if na else 0
                        out[o+3] = int(na * 255)
    png_write(dst, W * nframes, H, out)
    return W, H, nframes, [f[1] for f in frames], len(layers)

for src in sys.argv[2:]:
    name = os.path.splitext(os.path.basename(src))[0]
    dst = os.path.join(sys.argv[1], name + '.png')
    W, H, n, durs, nl = convert(src, dst)
    print(f'{name}: frame {W}x{H}, {n} frames, {nl} capas, duraciones {durs} ms -> {dst}')
