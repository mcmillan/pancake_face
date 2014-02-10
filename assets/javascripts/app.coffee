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

class @Facebook
  @loggedIn: false

  @init: ->
    FB.init(
      appId: Pancake.Config.facebookAppId
    )

    FB.getLoginStatus((response) =>
      @loggedIn = true if response.status == 'connected'
    )

  @login: (callback = ->) ->
    return callback() if @loggedIn

    FB.login((response) =>
      return unless response.status == 'connected'
      @loggedIn = true
      callback()
    , scope: 'user_photos')

@Facebook.init()

$('.js-pick-webcam').on('click', (event) ->
  event.preventDefault()
  $('.intro').fadeOut(300)
  $('.pick-webcam').delay(300).fadeIn(300)

  WebcamPicker.show()
)

$('.js-pick-facebook').on('click', (event) ->
  event.preventDefault()

  $('.intro').fadeOut(300)
  $('.pick-facebook').delay(300).fadeIn(300)

  Facebook.login(->
    FacebookPicker.show()
  )
)

$('.js-pick-instagram').on('click', (event) ->
  event.preventDefault()
  $('.intro').fadeOut(300)
  $('.pick-instagram').delay(300).fadeIn(300)

  InstagramPicker.show()
)

$('.js-pick-computer input').fileupload(
  dataType: 'json'
  url: '/detect'
  formData:
    type: 'computer'
  add: (event, data) ->
    $('.intro').fadeOut(300)
    $('.loading').delay(300).fadeIn(300, -> data.submit())
  done: (event, data) ->
    handleDetectionResponse(data.response().result)
)

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

handleDetectionResponse = (response) ->
  $.each(response.faces, (id, face) ->
    $('<a href="#" class="face panel" />')
      .css('backgroundImage', "url(#{response.url})")
      .css('backgroundPositionX', "#{-face.coordinates.top_left.x}px")
      .css('backgroundPositionY', "#{-face.coordinates.top_left.y}px")
      .css('width', "#{face.width}px")
      .css('height', "#{face.height}px")
      .data('id', id)
      .appendTo('section.face-selector .faces')
  )

  if $('section.face-selector .faces .face').length == 1
    $('section.face-selector .faces .face:first').click()
  else
    $('section.loading').fadeOut(300)
    $('section.face-selector').delay(300).fadeIn(300)

detect = (type, imageURL) ->
  $.ajax(
    url: '/detect'
    type: 'post'
    data:
      url: imageURL
      type: type
    success: handleDetectionResponse
    error: ->
      alert 'Something went wrong. Try again?'
  )

class @WebcamPicker
  @show: ->
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

  @success: (stream) =>
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

  @deviceError: ->
    alert 'Video device is not supported.'

  @capture: (event) =>
    event.preventDefault()

    if window.webcam.context == 'webrtc'
      video  = document.getElementsByTagName('video')[0]
      canvas = document.createElement('canvas')

      canvas.width  = video.videoWidth
      canvas.height = video.videoHeight
      canvas.getContext('2d').drawImage(video, 0, 0)

      imageURL = canvas.toDataURL()

      $('section.pick-webcam').fadeOut(300)
      $('section.loading').delay(300).fadeIn(300, ->
        detect('webcam', imageURL)
      )
    else if window.webcam.context == 'flash'
      alert 'wip!'

class @FacebookPicker
  @show: ->
    FB.api('/me/photos/uploaded?fields=source', (response) =>
      @renderGrid(response.data)
    )

    $('.pick-facebook').on('click', 'a.thumbnail', (event) ->
      event.preventDefault()
      $('section.pick-facebook').fadeOut(300)
      $('section.loading').delay(300).fadeIn(300, =>
        detect('facebook', $(this).find('img').attr('src'))
      )
    )

  @renderGrid: (photos) ->
    row = $('<div class="row">')
    $.each(photos, (id, image) ->
      $('<div class="col-sm-3">')
        .append(
          $('<a href="#" class="thumbnail">')
            .append(
              $('<img />').attr('src', image.source)
            )
        )
        .appendTo(row)

      if row.children().length == 4
        row.appendTo('.pick-facebook')
        row = $('<div class="row">')
    )

class @InstagramPicker
  @accessToken: false

  @show: (callback) ->
    return callback @accessToken if @accessToken

    screenX      = if typeof window.screenX != 'undefined' then window.screenX else window.screenLeft
    screenY      = if typeof window.screenY != 'undefined' then window.screenY else window.screenTop
    clientWidth  = if typeof window.outerWidth != 'undefined' then window.outerWidth else document.documentElement.clientWidth
    clientHeight = if typeof window.outerHeight != 'undefined' then window.outerHeight else (document.documentElement.clientHeight - 22)
    popupWidth   = 620
    popupHeight  = 300
    screenWidth  = if screenX < 0 then window.screen.width + screenX else screenX
    popupX       = parseInt(screenWidth + ((clientWidth - popupWidth) / 2), 10)
    popupY       = parseInt(screenY + ((clientHeight - popupHeight) / 2.5), 10)

    window.open '/auth/instagram', '_blank', "width=#{popupWidth},height=#{popupHeight},left=#{popupX},top=#{popupY},scrollbars=1,location=1,toolbar=0"


    $('.pick-instagram').on('click', 'a.thumbnail', (event) ->
      event.preventDefault()
      $('section.pick-instagram').fadeOut(300)
      $('section.loading').delay(300).fadeIn(300, =>
        detect('instagram', $(this).find('img').attr('src'))
      )
    )

  @renderGrid: (photos) ->
    row = $('<div class="row">')
    $.each(photos, (id, image) ->
      $('<div class="col-sm-3">')
        .append(
          $('<a href="#" class="thumbnail">')
            .append(
              $('<img />').attr('src', image)
            )
        )
        .appendTo(row)
        
      if row.children().length == 4
        row.appendTo('.pick-instagram')
        row = $('<div class="row">')
    )