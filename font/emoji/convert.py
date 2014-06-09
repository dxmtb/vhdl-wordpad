from PIL import Image
import glob

line = 7680
tot = 0
for f in glob.glob('*.png')*2:
    tot += 1
    if tot > 128:
        break
    im = Image.open(f)
    size = im.size
    assert(size[0] == 100)
    im = im.crop((0, 0, 100, 100))
    im.thumbnail((16, 16), Image.ANTIALIAS)
    im.save('new/%s' % f, "PNG")
#    pix = im.load()
#    print '\t--%s, %d;' % (f, tot)
#    for i in xrange(size[0]):
#        o = ''
#        for j in xrange(size[1]):
#            print pix[j, i]
#            if pix[j, i][3] > 128:
#                o = o + '1'
#            else:
#                o = o + '0'
#        print '\t %d : %s;' % (line, o)
#        line += 1
