module.exports =

##*
# Base class for providers.
##
class AbstractProvider
    ###*
     * The service (that can be used to query the source code and contains utility methods).
    ###
    service: null

    ###*
     * The call tip marker.
    ###
    callTipMarker: null

    ###*
     * Handle used for managing the timeout to use before triggering the cursor changed event handler.
    ###
    timeoutHandle: null

    ###*
     * Keeps track of event subscriptions to the cursor position changed event per editor.
    ###
    onDidChangeCursorPositionSubscriptions: null

    ###*
     * Constructor.
    ###
    constructor: () ->
        @onDidChangeCursorPositionSubscriptions = []

    ###*
     * Initializes this provider.
     *
     * @param {mixed} service
    ###
    activate: (@service) ->
        dependentPackage = 'language-php'

        # It could be that the dependent package is already active, in that case we can continue immediately. If not,
        # we'll need to wait for the listener to be invoked
        if atom.packages.isPackageActive(dependentPackage)
            @doActualInitialization()

        atom.packages.onDidActivatePackage (packageData) =>
            return if packageData.name != dependentPackage

            @doActualInitialization()

        atom.packages.onDidDeactivatePackage (packageData) =>
            return if packageData.name != dependentPackage

            @deactivate()

    ###*
     * Does the actual initialization.
    ###
    doActualInitialization: () ->
        atom.workspace.observeTextEditors (editor) =>
            if /text.html.php$/.test(editor.getGrammar().scopeName)
                @registerEvents(editor)

        # When you go back to only have one pane the events are lost, so need to re-register.
        atom.workspace.onDidDestroyPane (pane) =>
            panes = atom.workspace.getPanes()

            if panes.length == 1
                @registerEventsForPane(panes[0])

        # Having to re-register events as when a new pane is created the old panes lose the events.
        atom.workspace.onDidAddPane (observedPane) =>
            panes = atom.workspace.getPanes()

            for pane in panes
                if pane != observedPane
                    @registerEventsForPane(pane)

    ###*
     * Registers the necessary event handlers for the editors in the specified pane.
     *
     * @param {Pane} pane
    ###
    registerEventsForPane: (pane) ->
        for paneItem in pane.items
            if atom.workspace.isTextEditor(paneItem)
                if /text.html.php$/.test(paneItem.getGrammar().scopeName)
                    @registerEvents(paneItem)

    ###*
     * Deactives the provider.
    ###
    deactivate: () ->
        @removeCallTip()

        for subscription in @onDidChangeCursorPositionSubscriptions
            subscription.dispose()

        @onDidChangeCursorPositionSubscriptions = []

    ###*
     * Registers the necessary event handlers.
     *
     * @param {TextEditor} editor TextEditor to register events to.
    ###
    registerEvents: (editor) ->
        subscription = editor.onDidChangeCursorPosition (event) =>
            # Only execute for the first cursor.
            cursors = editor.getCursors()

            return if event.cursor != cursors[0]

            if @timeoutHandle?
                # Putting this here will ensure the popover is removed when the user currently has a call tip active and
                # then starts rapidly moving the cursor around. Otherwise, it will stick around for a while until the
                # user stops moving the cursor.
                @removeCallTip()

                clearTimeout(@timeoutHandle)
                @timeoutHandle = null

            @timeoutHandle = setTimeout ( =>
                @timeoutHandle = null
                @onChangeCursorPosition(editor, event.newBufferPosition)
            ), 30

        @onDidChangeCursorPositionSubscriptions.push(subscription)

    ###*
     * Shows the call tip at the specified location and editor with the specified text.
     *
     * @param {TextEditor} editor
     * @param {Point}      bufferPosition
     * @param {string}     text
    ###
    showCallTip: (editor, bufferPosition, text) ->
        @callTipMarker = editor.markBufferPosition(bufferPosition, {
            invalidate : 'touch'
        })

        rootDiv = document.createElement('div')
        rootDiv.className = 'tooltip bottom fade'
        rootDiv.style.opacity = 100
        rootDiv.style.fontSize = '1.0621em'

        innerDiv = document.createElement('div')
        innerDiv.className = 'tooltip-inner php-integrator-call-tip-wrapper'

        textDiv = document.createElement('div')
        textDiv.innerHTML = text

        innerDiv.appendChild(textDiv)
        rootDiv.appendChild(innerDiv)

        editor.decorateMarker(@callTipMarker, {
            type: 'overlay'
            class: 'php-integrator-call-tip'
            item: rootDiv
        })

    ###*
     * Removes the call tip, if it is displayed.
    ###
    removeCallTip: () ->
        if @callTipMarker
            @callTipMarker.destroy()
            @callTipMarker = null

    ###*
     * Invoked when the cursor position changes in an editor.
     *
     * @param {TextEditor} editor
     * @param {Point}      newBufferPosition
    ###
    onChangeCursorPosition: (editor, newBufferPosition) ->
        throw new Error("This method is abstract and must be implemented!")
