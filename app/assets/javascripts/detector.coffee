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
    $('.state.state-intro .alert').remove()

    if response.faces.length == 0
      $('<div class="alert alert-danger" />')
        .text("We weren't able to find a face in that photo. Try again?")
        .insertBefore('.state.state-intro .js-pick-webcam')
        $('.state.state-loading').fadeOut(300).promise().done(->
          $('.state.state-intro').delay(300).fadeIn(300)
        )
      return

    $('.state.state-face-selector .faces').empty()

    row = $('<div class="row">')
    $.each(response.faces, (id, face) ->
      $('<div class="col-sm-4">')
        .append(
          $('<a href="#" class="thumbnail face">')
            .append(
              $('<img />').attr('src', "/detected/#{id}")
            )
            .data('id', id)
        )
        .appendTo(row)

      if row.children().length == 3
        row.appendTo('.state.state-face-selector .faces')
        row = $('<div class="row">')
    )
    row.appendTo('.state.state-face-selector .faces')

    if $('.state.state-face-selector .faces .face').length == 1
      $('.state.state-face-selector .faces .face:first').click()
    else
      $('.state.state-loading').fadeOut(300).promise().done(->
        $('.state.state-face-selector').delay(300).fadeIn(300)
      )