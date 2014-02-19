class @Pancake.InstagramPicker
  @accessToken: false

  @init: ->
    $('.state.state-pick-instagram').on('click', 'a.thumbnail', @clickThumbnail)

  @show: (event) ->
    event.preventDefault()

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

  @popupCallback: (photos) ->
    $('.state.state-intro').fadeOut(300).promise().done(=>
      @renderGrid(photos)
    )

  @clickThumbnail: (event) ->
    event.preventDefault()
    $('.state.state-pick-instagram').fadeOut(300).promise().done(=>
      Pancake.Detector.detect('instagram', $(this).find('img').attr('src'))
    )

  @renderGrid: (photos) ->
    $('.state.state-pick-instagram .grid').empty()
    
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
        row.appendTo('.state.state-pick-instagram .grid')
        row = $('<div class="row">')
    )

    $('.state.state-pick-instagram').fadeIn(300)
