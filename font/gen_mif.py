files = ['./128_tnr_14.out', './128_csm_14.out',
         './128_tnr_16.out', './128_csm_16.out']

shift = 0
for f in files:
    l = int(f.split('_')[2].strip('.out'))
    rsize = l*l
    size = l * l / 8 * 8
    if size < l*l:
        size += 8
    with open(f) as fin:
        fin.readline()
        for i in xrange(128):
            for line in fin:
                line = line.strip()
                if len(line) == 0 or line[0] == r'/':
                    continue
                assert(int(line) == i)
                break
            bitmap = ''
            for line in fin:
                line = line.strip()
                if len(line) == 0:
                    continue
                if line[0] == r'/':
                    break
                assert(line[:2] == '0x')
                num = int(line, 0)
                bitmap += '{0:08b}'.format(num)
            assert(len(bitmap) == size)
            bitmap = bitmap[:rsize]
            print '\t--%s %d' % (f, i)#, chr(i)
            for j in xrange(l):
#               print bitmap[j*l:(j+1)*l]
                print '\t%d : %s' % (shift, '0'*(16-l)+bitmap[j*l:(j+1)*l])
                shift += 1
