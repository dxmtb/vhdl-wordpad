from PIL import Image
files = ['small.png', 'big.png', 'font1.png', 'font2.png', 'save.png', 'open.png']
line = 0
for f in files:
    im = Image.open(f)
    size = im.size
    assert(size[0] == 35 and size[1] == 35)
    pix = im.load()
    print '\t--%s;' % f
    for i in xrange(size[0]):
        o = ''
        for j in xrange(size[1]):
            if pix[j, i][3] > 128:
                o = o + '1'
            else:
                o = o + '0'
        print '\t %d : %s;' % (line, o)
        line += 1
