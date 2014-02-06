filepicker.setKey('A5iPA0dMlTkG0ebazF5XCz')

filepicker.pick(
  mimetype: 'image/*',
  services: ['FACEBOOK', 'INSTAGRAM', 'WEBCAM', 'COMPUTER']
  container: 'picker'
, (inkBlob) ->
  
  $('section.upload').fadeOut(300)
  $('section.loading').delay(300).fadeIn(300, ->
    $.ajax(
      url: '/detect'
      type: 'post'
      data:
        url: inkBlob.url
      success: (response) ->
        $('section.loading').fadeOut(300)
        $('section.face-selector').delay(300).fadeIn(300)

        $.each(response.faces, (id, face) ->
          $('<a href="#" class="face panel" />')
            .css('backgroundImage', "url(#{response.image_url})")
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
, (error) ->
  console.log error
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