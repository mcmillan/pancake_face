class @Pancake.GallerySubmission
  @processing: false

  @init: ->
    $('.gallery-submission form').on('submit', @submitForm)

  @submitForm: (event) =>
    event.preventDefault()

    return if @processing

    @processing = true

    target      = $(event.currentTarget)
    name        = target.find('.name').val()
    email       = target.find('.email').val()
    tos         = if target.find('.tos').is(':checked') then 1 else 0


    $('.gallery-submission form').fadeTo(300, 0.5).promise().done(=>
      $.ajax(
        url: '/gallery/competition'
        type: 'post'
        data:
          name: name
          email: email
          tos: tos
        success: @success
        error: @error
      )
    )

  @success: (response) ->
    $('.gallery-submission form').slideUp(300)
    $('.gallery-submission .success').slideDown(300)

  @error: (jqXHR) =>
    message = if jqXHR.responseJSON? then jqXHR.responseJSON.error else jqXHR.statusText

    if $('.gallery-submission form .alert.alert-danger').length > 0
      $('.gallery-submission form .alert.alert-danger').text(message)
    else
      $('<div class="alert alert-danger" style="margin: 0 15px 15px" />')
        .text(message)
        .hide()
        .prependTo('.gallery-submission form')
        .slideDown(300)

    $('.gallery-submission form').fadeTo(300, 1)

    @processing = false