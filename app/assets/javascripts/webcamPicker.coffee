class @Pancake.WebcamPicker
  @pos: 0

  @show: (event) =>
    event.preventDefault()

    @options =
      audio: false
      video: true
      
      el: 'webcam'
      
      extern: null
      append: true

      width: 640
      height: 480

      mode: 'callback'
      swffile: '/img/webcam_fallback.swf'
      quality: 90

      onCapture: ->
        window.webcam.save()

      onSave: (data) =>
        col    = data.split(';')
        i      = 0

        while i < @options.width
          x = parseInt(col[i], 10)
          @imageData.data[@pos]     = (x >> 16) & 0xff
          @imageData.data[@pos + 1] = (x >> 8) & 0xff
          @imageData.data[@pos + 2] = x & 0xff
          @imageData.data[@pos + 3] = 0xff
          @pos += 4
          ++i
        
        if @pos >= 2 * @options.width * @options.height
          @ctx.putImageData(@imageData, 0, 0)
          imageURL = @canvas.toDataURL()
          @pos = 0

          $('#webcam').empty()
          $('.state.state-pick-webcam').fadeOut(300).promise().done(->
            Pancake.Detector.detect('webcam', imageURL)
          )

    @canvas        = document.createElement('canvas')
    G_vmlCanvasManager.initElement(@canvas) if !@canvas.getContext
    @canvas.width  = @options.width
    @canvas.height = @options.height
    @ctx           = @canvas.getContext('2d')
    @imageData     = @ctx.getImageData(0, 0, @options.width, @options.height)

    getUserMedia(@options, @success, @deviceError)

    window.webcam = @options

    $('.js-webcam-capture').on('click', @capture)
    $('.state.state-intro')
      .fadeOut(300)
      .promise()
      .done(-> $('.state.state-pick-webcam').fadeIn(300))

  @success: (stream) =>
    return unless window.webcam.context == 'webrtc'

    @stream = stream
    
    video = window.webcam.videoEl

    if (typeof MediaStream != 'undefined' and MediaStream != null) and @stream instanceof MediaStream
      video[if video.mozSrcObject? then 'mozSrcObject' else 'src'] = @stream
      return video.play()

    vendorURL = window.URL or window.webkitURL
    video.src = if vendorURL then vendorURL.createObjectURL(@stream) else @stream

    video.onError = =>
      @stream.stop()
      @deviceError()

  @deviceError: ->
    alert 'Video device is not supported.'

  @capture: (event) =>
    event.preventDefault()

    if window.webcam.context == 'webrtc'
      video  = $('.state.state-pick-webcam video').get(0)
      @ctx.drawImage(video, 0, 0)

      imageURL = @canvas.toDataURL()

      $('#webcam').empty()
      @stream.stop() if typeof @stream != 'undefined'

      $('.state.state-pick-webcam').fadeOut(300).promise().done(->
        Pancake.Detector.detect('webcam', imageURL)
      )
    else if window.webcam.context == 'flash'
      window.webcam.capture()