class @Pancake.WebcamPicker
  @show: (event) =>
    event.preventDefault()

    @options =
      audio: false
      video: true
      
      el: 'webcam'
      
      extern: null
      append: true

      width: 600
      height: 450

      mode: 'save'
      swffile: '/img/webcam_fallback.swf'
      quality: 90

      onSave: (data) ->
        console.log data

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
      canvas = document.createElement('canvas')

      canvas.width  = video.videoWidth
      canvas.height = video.videoHeight
      canvas.getContext('2d').drawImage(video, 0, 0)

      imageURL = canvas.toDataURL()

      $('#webcam').empty()
      @stream.stop() if typeof @stream != 'undefined'

      $('.state.state-pick-webcam').fadeOut(300).promise().done(->
        Pancake.Detector.detect('webcam', imageURL)
      )
    else if window.webcam.context == 'flash'
      alert 'Something went wrong. Please try again.'