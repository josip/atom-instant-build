{$} = require 'atom-space-pen-views'

ROOT_CLASS = 'instant-build-status'
ELEMENT_VISIBLE_CLASS = 'bb-visible'
ELEMENT_HIDDEN_CLASS = 'bb-hidden'
SPINNER_CLASS = 'instant-build-spinner'
STATUS_TEXT_CLASS = 'instant-build-status-text'

module.exports =
class StatusBarView
  constructor: (serializedState) ->
    @element = $("""
        <span class="#{ROOT_CLASS} #{ELEMENT_HIDDEN_CLASS}">
          <div class="#{SPINNER_CLASS}" style="display:none"></div>
          <i class="icon"></i>
          <span class="#{STATUS_TEXT_CLASS}"></span>
        </span>
      """)

  getComponent: (className) ->
    @element.find(".#{className}")

  setStatus: (status, message, {resetAfterTimeout}) ->
    clearTimeout(@_statusReset) if @_statusReset

    @getComponent(STATUS_TEXT_CLASS).html(message)
    @element.attr('class', "#{ROOT_CLASS} #{ELEMENT_VISIBLE_CLASS} #{status}")

    if resetAfterTimeout
      @_statusReset = setTimeout((=> @clearStatus()), 2000)

  clearStatus: () ->
    clearTimeout(@_statusReset) if @_statusReset
    @_statusReset = null

    @element
      .removeClass(ELEMENT_VISIBLE_CLASS)
      .addClass(ELEMENT_HIDDEN_CLASS)

  setSpinnerVisibility: (state) ->
    return if state isnt 'hide' and state isnt 'show'
    @getComponent(SPINNER_CLASS)[state]()

  setStatusIcon: (iconName) ->
    @element.find('i').attr('class', "icon #{iconName}")

  serialize: -> {}

  destroy: ->
    @element.remove()

  getElement: ->
    @element
