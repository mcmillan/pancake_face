class @Pancake.Generator
  @processing: false
  @sway: 0
  @pan: 'jamie'

  @init: ->
    $('.state.state-face-selector .faces').on('click', '.face', @chooseFaceFromSelector)
    $('section.step-2 .pan-selector-list li figure').on('click', @changePan)
    $('section.step-2 .tweaker-wrapper .btn-tweak').on('click', @changeSway)

  @chooseFaceFromSelector: (event) =>
    event.preventDefault()
    @faceID = $(event.currentTarget).data('id')
  
    $('.state.state-face-selector').fadeOut(300).promise().done(=>
      @generate()
    )

  @focusImage: ->
    $('html, body').animate(scrollTop: 225)

  @changePan: (event) =>
    event.preventDefault()
    return if @processing

    @pan = $(event.currentTarget).data('pan')
    @generate()
    @focusImage()

  @changeSway: (event) =>
    event.preventDefault()
    return if @processing

    change = if $(event.currentTarget).hasClass('js-tweak-darker') then 5 else -5
    @sway += change
    @generate()
    @focusImage()

  @generate: ->
    @processing = true
    $('section.step-2 .tweaker-wrapper').fadeTo(300, 0.5) if $('section.step-2 .tweaker-wrapper').is(':visible')
    $('.state.state-loading').fadeIn(300).promise().done(=>
      $.ajax(
        url: '/generate'
        type: 'post'
        data:
          face: @faceID
          pan: @pan
          sway: @sway
        success: @success
        error: @error
      )
    )

  @success: (response) =>
    $('section.step-2 .tweaker-wrapper')
      .fadeTo(300, 1)
      .find('img')
        .attr('src', response.file)
      

    $('section.step-2 .js-pan-name div')
      .hide()
      .filter('[data-pan="' + response.pan + '"]')
      .show()

    $('section.step-2 .tweaker-wrapper .js-tweak-darker')[if response.canDarken then 'show' else 'hide']()
    $('section.step-2 .tweaker-wrapper .js-tweak-lighter')[if response.canLighten then 'show' else 'hide']()

    $('section.step-2 .pan-selector-list li figure')
      .removeClass('selected')
      .filter('[data-pan="' + response.pan + '"]')
      .addClass('selected')

    $('.steps-list li[data-step=2]').addClass('selected')

    $('section.step-1').fadeOut(300).promise().done(=>
      $('section.step-2').fadeIn(300)
      @processing = false
    )

  @error: =>
    alert 'Something went wrong. Try again?'
    @processing = false