class @Pancake.Detector
  @detect: (type, imageURL) ->
    $('.state.state-loading').fadeIn(300).promise().done(=>
      $.ajax(
        url: '/detect'
        type: 'post'
        data:
          url: imageURL
          type: type
        success: @success
        error: ->
          alert 'Something went wrong. Try again?'
      )
    )


  @success: (response) ->
    $.each(response.faces, (id, face) ->
      $('<a href="#" class="face panel" />')
        .css('backgroundImage', "url(#{response.url})")
        .css('backgroundPositionX', "#{-face.coordinates.top_left.x}px")
        .css('backgroundPositionY', "#{-face.coordinates.top_left.y}px")
        .css('width', "#{face.width}px")
        .css('height', "#{face.height}px")
        .data('id', id)
        .appendTo('.state.state-face-selector .faces')
    )

    if $('.state.state-face-selector .faces .face').length == 1
      $('.state.state-face-selector .faces .face:first').click()
    else
      $('.state.state-loading').fadeOut(300).promise().done(->
        $('.state.state-face-selector').delay(300).fadeIn(300)
      )