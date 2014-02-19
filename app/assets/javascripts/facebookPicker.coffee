class @Pancake.FacebookPicker
  @loggedIn: false

  @init: ->
    FB.init(
      appId: Pancake.Config.facebookAppId
    )

    FB.getLoginStatus((response) =>
      @loggedIn = true if response.status == 'connected'
    )

    $('.state.state-pick-facebook').on('click', 'a.thumbnail', @clickThumbnail)

  @login: (callback = ->) ->
    return callback() if @loggedIn

    FB.login((response) =>
      return unless response.status == 'connected'
      @loggedIn = true
      callback()
    , scope: 'user_photos')

  @show: (event) =>
    event.preventDefault()

    @login(=>
      $('.state.state-intro').fadeOut(300).promise().done(=>
        $('.state.state-loading').fadeIn(300).promise().done(=>
          FB.api('/me/photos/uploaded?fields=source', (response) =>
            @renderGrid(response.data)
          )
        )
      )
    )

  @clickThumbnail: (event) ->
    event.preventDefault()
    $('.state.state-pick-facebook').fadeOut(300).promise().done(=>
      Pancake.Detector.detect('facebook', $(this).find('img').attr('src'))
    )

  @renderGrid: (photos) ->
    $('.state.state-pick-facebook .grid').empty()

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
        row.appendTo('.state.state-pick-facebook .grid')
        row = $('<div class="row">')
    )

    $('.state.state-loading').fadeOut(300).promise().done(->
      $('.state.state-pick-facebook').fadeIn(300)
    )