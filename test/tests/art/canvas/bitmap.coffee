define [
  'art.foundation/src/art/dev_tools/test/art_chai'
  'art.atomic'
  'art.foundation'
  'art.canvas'
  './common_bitmap_tests'
], (chai, Atomic, Foundation, Canvas, commonBitmapTests) ->
  assert = chai.assert
  {Binary, log, eq} = Foundation
  {point, point0, point1, rect, color, matrix, Matrix} = Atomic

  array = (a) -> i for i in a

  commonBitmapTests Canvas.Bitmap, "Canvas.Bitmap"

  reducedRange = (data, factor = 32) ->
    Math.round a / factor for a in data

  generateTestBitmap = ->
    result = new Canvas.Bitmap point(5, 5)
    w = result.size.w
    imageData = result.getImageData()
    data = imageData.data
    for y in [0..4]
      for x in [0..4]
        data[((y * w) + x) * 4] = x * 255/4
        data[((y * w) + x) * 4 + 3] = y * 255/4
    result.putImageData imageData

    log result
    result

  generateTestBitmap2 = (c = "#f00")->
    result = new Canvas.Bitmap point(90, 90)
    result.clear()
    result.drawRectangle point(), point(60,60), color:c
    result

  generateTestBitmap3 = (c = "#00f")->
    result = new Canvas.Bitmap point(90, 90)
    result.clear()
    result.drawRectangle point(30,30), point(60,60), color:c
    result

  suite "Art.Canvas.Bitmap", ->
    test "allocate", ->
      bitmap = new Canvas.Bitmap point(400, 300)
      assert.equal 400, bitmap.size.x

    test "getImageDataArray (all channels)", ->
      bitmap = new Canvas.Bitmap point(2, 2)
      bitmap.clear color 1/255, 2/255, 3/255, 255/255
      data = bitmap.getImageDataArray()
      assert.eq data, [1, 2, 3, 255, 1, 2, 3, 255, 1, 2, 3, 255, 1, 2, 3, 255]

    test "getImageDataArray (red channel)", ->
      bitmap = new Canvas.Bitmap point(2, 2)
      bitmap.clear color 1/255, 2/255, 3/255, 255/255
      data = bitmap.getImageDataArray("red")
      assert.eq data, [1, 1, 1, 1]

    test "clear", ->
      bitmap = new Canvas.Bitmap point(2, 2)
      bitmap.drawRectangle null, rect(0, 0, 2, 2), color:"red"
      bitmap.clear()
      assert.eq bitmap.getImageDataArray(), [
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
      ]

    test "clear '#f1f1f1'", ->
      bitmap = new Canvas.Bitmap point(2, 2)
      bitmap.drawRectangle null, rect(0, 0, 2, 2), color:"red"
      bitmap.clear "#f1a52f"
      assert.eq bitmap.getImageDataArray(), [
        241, 165, 47, 255
        241, 165, 47, 255
        241, 165, 47, 255
        241, 165, 47, 255
      ]

    test "new", ->
      bitmap = new Canvas.Bitmap point(2, 2)
      assert.eq bitmap.getImageDataArray(), [
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
      ]

    suite "stroke", ->

      test "drawLine", ->
        bitmap = new Canvas.Bitmap point 3
        bitmap.drawLine null, point0, point(3), color: "white"
        assert.eq (v * 8 / 255 | 0 for v in bitmap.getImageDataArray("red")), [
          8,0,0
          0,8,0
          0,0,8
        ]

      test "drawBorder", ->
        bitmap = new Canvas.Bitmap point 3
        bitmap.drawBorder null, rect(0,0,3,3), color: "white"
        assert.eq (v * 8 / 255 | 0 for v in bitmap.getImageDataArray("red")), [
          8,8,8
          8,0,8
          8,8,8
        ]

      test "strokeRectangle lineWidth:1", ->
        bitmap = new Canvas.Bitmap point(6, 6)
        bitmap.clear "black"
        bitmap.pixelSnap = false
        bitmap.strokeRectangle null, rect(1, 1, 4, 4), color:"red", lineWidth:1, lineJoin:"miter"
        log bitmap
        data = reducedRange(bitmap.getImageDataArray("red"))
        unless eq(data, [
          0, 4, 4, 4, 4, 0,
          4, 8, 4, 4, 8, 4,
          4, 4, 0, 0, 4, 4,
          4, 4, 0, 0, 4, 4,
          4, 8, 4, 4, 8, 4,
          0, 4, 4, 4, 4, 0
        ])
          assert.eq data, [
            2, 4, 4, 4, 4, 2,
            4, 6, 4, 4, 6, 4,
            4, 4, 0, 0, 4, 4,
            4, 4, 0, 0, 4, 4,
            4, 6, 4, 4, 6, 4,
            2, 4, 4, 4, 4, 2
          ]


      renderStrokeRectangleWithSnap = (where, r, opts) ->
        m = matrix where
        r2 = m.transform r.br
        size = r2.add(point (opts.lineWidth/2 || 1)).ceil()
        log size:size
        bitmap = new Canvas.Bitmap size
        bitmap.pixelSnap = true
        bitmap.clear "black"
        opts.color = "#f00"
        bitmap.strokeRectangle where, r, opts
        scale = 20
        b2 = new Canvas.Bitmap bitmap.size.mul scale
        b2.imageSmoothing = false
        b2.drawBitmap Matrix.scale(scale), bitmap
        opts.color = "#0fff"
        opts.compositeMode = "add"
        b2.pixelSnap = false
        b2.strokeRectangle m.scale(scale), r, opts
        log b2
        bitmap

      test "strokeRectangle pixelSnap=true lineWidth:1 ", ->
        bitmap = renderStrokeRectangleWithSnap null, rect(1, 1, 4, 4), color:"red", lineWidth:1
        assert.eq reducedRange(bitmap.getImageDataArray("red")), [
          0, 0, 0, 0, 0, 0,
          0, 8, 8, 8, 8, 0,
          0, 8, 0, 0, 8, 0,
          0, 8, 0, 0, 8, 0,
          0, 8, 8, 8, 8, 0,
          0, 0, 0, 0, 0, 0
        ]

      test "strokeRectangle pixelSnap=true lineWidth:.5 ", ->
        bitmap = renderStrokeRectangleWithSnap null, rect(1, 1, 4, 4), color:"red", lineWidth:.5
        assert.eq reducedRange(bitmap.getImageDataArray("red")), [
          0, 0, 0, 0, 0, 0,
          0, 6, 4, 4, 6, 0,
          0, 4, 0, 0, 4, 0,
          0, 4, 0, 0, 4, 0,
          0, 6, 4, 4, 6, 0,
          0, 0, 0, 0, 0, 0
        ]

      test "strokeRectangle pixelSnap=true lineWidth:1.5 ", ->
        bitmap = renderStrokeRectangleWithSnap null, rect(1, 1, 4, 4), color:"red", lineWidth:1.5
        assert.eq reducedRange(bitmap.getImageDataArray("red")), [
          2, 4, 4, 4, 4, 2,
          4, 8, 8, 8, 8, 4,
          4, 8, 0, 0, 8, 4,
          4, 8, 0, 0, 8, 4,
          4, 8, 8, 8, 8, 4,
          2, 4, 4, 4, 4, 2
        ]

      test "strokeRectangle pixelSnap=true lineWidth:1, scale:1.5,1", ->
        bitmap = renderStrokeRectangleWithSnap Matrix.scale(1.5,1), rect(.5, 1, 3, 4), color:"red", lineWidth:1, lineJoin:"miter"
        assert.eq reducedRange(bitmap.getImageDataArray("red")), [
          0, 0, 0, 0, 0, 0
          0, 8, 8, 8, 8, 0
          0, 8, 4, 4, 8, 0
          0, 8, 4, 4, 8, 0
          0, 8, 8, 8, 8, 0
          0, 0, 0, 0, 0, 0
        ]

      test "strokeRectangle pixelSnap=true lineWidth:2", ->
        bitmap = renderStrokeRectangleWithSnap null, rect(1, 1, 4, 4), color:"red", lineWidth:2, lineJoin:"miter"
        assert.eq reducedRange(bitmap.getImageDataArray("red")), [
          8, 8, 8, 8, 8, 8
          8, 8, 8, 8, 8, 8
          8, 8, 0, 0, 8, 8
          8, 8, 0, 0, 8, 8
          8, 8, 8, 8, 8, 8
          8, 8, 8, 8, 8, 8
        ]

      test "strokeRectangle pixelSnap=true lineWidth:3", ->
        bitmap = renderStrokeRectangleWithSnap null, rect(2, 2, 5, 5), color:"red", lineWidth:3, lineJoin:"miter"
        assert.eq reducedRange(bitmap.getImageDataArray("red")), [
          0, 0, 0, 0, 0, 0, 0, 0, 0
          0, 8, 8, 8, 8, 8, 8, 8, 0
          0, 8, 8, 8, 8, 8, 8, 8, 0
          0, 8, 8, 8, 8, 8, 8, 8, 0
          0, 8, 8, 8, 0, 8, 8, 8, 0
          0, 8, 8, 8, 8, 8, 8, 8, 0
          0, 8, 8, 8, 8, 8, 8, 8, 0
          0, 8, 8, 8, 8, 8, 8, 8, 0
          0, 0, 0, 0, 0, 0, 0, 0, 0

        ]


    suite "fill", ->
      test "compositing", ->
        a = generateTestBitmap2 "#f00"
        log a
        b = generateTestBitmap3 "#00f"
        log b
        modes = [
          'source-over','source-in','source-out','source-atop',
          'destination-over','destination-in','destination-out','destination-atop',
          'lighter','darker','copy','xor'
          'normal', 'multiply', 'screen', 'overlay',
          'darken', 'lighten', 'color-dodge', 'color-burn',
          'hard-light', 'soft-light', 'difference', 'exclusion'
          'hue', 'saturation', 'color', 'luminocity'
        ]
        s = b.size
        step = s.add 10
        dest = new Canvas.Bitmap step.mul point(4,(modes.length+3)/4)

        for m, mi in modes
          p = point(mi % 4, mi / 4).floor().mul step
          temp = new Canvas.Bitmap b.size
          temp.drawBitmap point(), a
          temp.drawBitmap point(), b, m
          dest.drawBitmap p, temp
          # dest.drawBitmap p, a
          # dest.drawBitmap p, b, "source-atop"
        log dest

      test "drawRectangle", ->
        bitmap = new Canvas.Bitmap point(4, 4)
        bitmap.drawRectangle null, rect(1, 1, 2, 2), color:"red"
        b2 = new Canvas.Bitmap point(4, 4)
        b2.clear "#000"
        log bitmap
        log b2
        b2.drawBitmap point(), bitmap
        log b2
        assert.eq bitmap.getImageDataArray("red"), [
          0,   0,   0, 0,
          0, 255, 255, 0,
          0, 255, 255, 0,
          0,   0,   0, 0
        ]

        bitmap.drawRectangle null, rect(2, 2, 2, 2), color:"#700"
        assert.eq bitmap.getImageDataArray("red"), [
          0,   0,   0,   0,
          0, 255, 255,   0,
          0, 255, 119, 119,
          0,   0, 119, 119
        ]

      test "drawRectangle radius:20", ->
        bitmap = new Canvas.Bitmap point 100, 100
        bitmap.clear "#ddd"
        bitmap.drawRectangle point(10, 10), point(80, 80), color:"red", radius:20
        log bitmap

    suite "toImage", ->
      test "pixelsPerPoint=2", (done)->
        bitmap = new Canvas.Bitmap point 100, 80
        bitmap.clear "orange"
        bitmap.pixelsPerPoint = 2
        log bitmap:bitmap
        bitmap.toImage (img) ->
          log img:img
          assert.eq img.width, 50
          assert.eq img.height, 40
          done()

      test "basic", (done)->
        bitmap = new Canvas.Bitmap point 100, 80
        bitmap.clear "orange"
        log bitmap:bitmap
        bitmap.toImage (img) ->
          log img:img
          assert.eq img.width, 100
          assert.eq img.height, 80
          done()