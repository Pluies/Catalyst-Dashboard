class Dashing.Meter extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue
  @accessor 'bgColor'

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".meter").val(value).trigger('change')

  ready: ->
    meter = $(@node).find(".meter")
    $(@node).css('background-color', @get('bgColor'))
    meter.attr("data-bgcolor", meter.css("background-color"))
    meter.attr("data-fgcolor", meter.css("color"))
    meter.knob()

  onData: (data) ->
    console.log('meter data received... performance:' + data.performance)
    if data.currentResult isnt data.lastResult
      $(@node).fadeOut().css('background-color', @get('bgColor')).fadeIn()
    if data.performance is 'good'
      $(@node).find('.more-info').hide()
      @set 'bgColor', "#96BF48"
    else if data.performance is 'meh'
      $(@node).find('.more-info').show()
      @set 'bgColor', "#ffd900"
    else if data.performance is 'bad'
      $(@node).find('.more-info').show()
      @set 'bgColor', "#C70015"
    $(@node).css('background-color', @get('bgColor'))


