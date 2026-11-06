# APK para instalar a mano (< 100 MB): extractNativeLibs=true en el manifiesto y las .so comprimidas
import sys, struct, zipfile
src, dst = sys.argv[1], sys.argv[2]
zi = zipfile.ZipFile(src)
m = bytearray(zi.read('AndroidManifest.xml'))
off = 8; rmap = []; hits = 0
while off < len(m):
    t, hs, sz = struct.unpack_from('<HHI', m, off)
    if t == 0x0180:
        rmap = list(struct.unpack_from('<%dI' % ((sz - 8) // 4), m, off + 8))
    elif t == 0x0102:
        ast, asz, acnt = struct.unpack_from('<HHH', m, off + 16 + 8)
        a0 = off + 16 + ast
        for k in range(acnt):
            p = a0 + k * asz
            name = struct.unpack_from('<I', m, p + 4)[0]
            if name < len(rmap) and rmap[name] == 0x010104ea:
                assert m[p + 15] == 0x12
                struct.pack_into('<I', m, p + 16, 0xFFFFFFFF); hits += 1
    off += sz
assert hits == 1, hits
zo = zipfile.ZipFile(dst, 'w')
for i in zi.infolist():
    if i.filename.startswith('META-INF/'):
        continue
    d = bytes(m) if i.filename == 'AndroidManifest.xml' else zi.read(i)
    c = zipfile.ZIP_STORED if i.filename == 'resources.arsc' or i.compress_type == zipfile.ZIP_STORED and not i.filename.endswith('.so') else zipfile.ZIP_DEFLATED
    n = zipfile.ZipInfo(i.filename, i.date_time); n.compress_type = c; n.external_attr = i.external_attr
    zo.writestr(n, d, compresslevel=9 if c == zipfile.ZIP_DEFLATED else None)
zo.close()
print('ok')
