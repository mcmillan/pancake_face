# filepicker.setKey('A5iPA0dMlTkG0ebazF5XCz')

# filepicker.pick(
#   mimetype: 'image/*',
#   services: ['FACEBOOK', 'INSTAGRAM', 'WEBCAM', 'COMPUTER']
#   container: 'picker'
# , (inkBlob) ->
  
#   $('section.upload').fadeOut(300)
#   $('section.loading').delay(300).fadeIn(300, ->
#     $.ajax(
#       url: '/detect'
#       type: 'post'
#       data:
#         url: inkBlob.url
#       success: (response) ->
#         $('section.loading').fadeOut(300)
#         $('section.face-selector').delay(300).fadeIn(300)

#         $.each(response.faces, (id, face) ->
#           $('<a href="#" class="face panel" />')
#             .css('backgroundImage', "url(#{response.image_url})")
#             .css('backgroundPositionX', "#{-face.coordinates.top_left.x}px")
#             .css('backgroundPositionY', "#{-face.coordinates.top_left.y}px")
#             .css('width', "#{face.width}px")
#             .css('height', "#{face.height}px")
#             .data('id', id)
#             .appendTo('section.face-selector .faces')
#         )
#       error: ->
#         alert 'Something went wrong. Try again?'
#     )
#   )
# , (error) ->
#   console.log error
# )

$('section.face-selector .faces').on('click', '.face', (event) ->
  event.preventDefault()
  id = $(this).data('id')
  $('section.face-selector').fadeOut(300)
  $('section.loading').delay(300).fadeIn(300, ->
    $.ajax(
      url: '/generate'
      type: 'post'
      data:
        id: id
      success: (response) ->
        $('section.loading').fadeOut(300)
        $('section.result').append("<img src='#{response.file}'>").delay(300).fadeIn(300)
      error: ->
        alert 'Something went wrong. Try again?'
    )
  )
)

class @WebcamPicker
  constructor: ->
    @options =
      audio: false
      video: true
      
      el: 'webcam'
      
      extern: null
      append: true

      width: 640
      height: 480

      mode: 'save'
      swffile: '/img/webcam_fallback.swf'
      quality: 90

      onSave: (data) ->
        console.log data

    getUserMedia(@options, @success, @deviceError)

    window.webcam = @options

    $('.webcam-capture').on('click', @capture)

  success: (stream) =>
    return unless window.webcam.context == 'webrtc'
    
    video = window.webcam.videoEl

    if (typeof MediaStream != 'undefined' and MediaStream != null) and stream instanceof MediaStream
      video[if video.mozSrcObject? then 'mozSrcObject' else 'src'] = stream
      return video.play()

    vendorURL = window.URL or window.webkitURL
    video.src = if vendorURL then vendorURL.createObjectURL(stream) else stream

    video.onError = =>
      stream.stop()
      @deviceError()

  deviceError: ->
    alert 'Video device is not supported.'

  capture: (event) =>
    event.preventDefault()

    if window.webcam.context == 'webrtc'
      video  = document.getElementsByTagName('video')[0]
      canvas = document.createElement('canvas')

      canvas.width  = video.videoWidth
      canvas.height = video.videoHeight
      canvas.getContext('2d').drawImage(video, 0, 0)

      imageURL = canvas.toDataURL()

      $('section.upload').fadeOut(300)
      $('section.loading').delay(300).fadeIn(300, ->
        $.ajax(
          url: '/detect'
          type: 'post'
          data:
            url: imageURL
          success: (response) ->
            $('section.loading').fadeOut(300)
            $('section.face-selector').delay(300).fadeIn(300)

            $.each(response.faces, (id, face) ->
              $('<a href="#" class="face panel" />')
                .css('backgroundImage', "url(#{imageURL})")
                .css('backgroundPositionX', "#{-face.coordinates.top_left.x}px")
                .css('backgroundPositionY', "#{-face.coordinates.top_left.y}px")
                .css('width', "#{face.width}px")
                .css('height', "#{face.height}px")
                .data('id', id)
                .appendTo('section.face-selector .faces')
            )
          error: ->
            alert 'Something went wrong. Try again?'
        )
      )
    else if window.webcam.context == 'flash'
      alert 'wip!'

new @WebcamPicker