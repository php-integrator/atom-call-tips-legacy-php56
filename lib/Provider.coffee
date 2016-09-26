AbstractProvider = require './AbstractProvider'

module.exports =

##*
# Provides tooltips for global constants.
##
class Provider extends AbstractProvider
    ###*
     * @inheritdoc
    ###
    onChangeCursorPosition: (editor, newBufferPosition) ->
        @removeCallTip()

        failureHandler = () ->
            return # I do absolutely nothing!

        getInvocationInfoHandler = (invocationInfo) =>
            return if not invocationInfo?

            callStack = invocationInfo.callStack.slice()

            method = null
            itemName = callStack.pop()

            return if not callStack

            if callStack.length > 0 or invocationInfo.type == 'instantiation'
                if invocationInfo.type == 'instantiation'
                    callStack.push(itemName)
                    itemName = '__construct'

                offset = @service.getCharacterOffsetFromByteOffset(invocationInfo.offset, editor.getBuffer().getText())

                deduceTypesSuccessHandler = (types) =>
                    successHandler = (classInfoArray) =>
                        for classInfo in classInfoArray
                            callTipText = null

                            if itemName of classInfo.methods
                                callTipText = @getFunctionCallTip(classInfo.methods[itemName], invocationInfo.argumentIndex)

                            else if itemName == '__construct'
                                # Not all classes have an explicit constructor, if none is specified, a public one
                                # exists, so pretend there are no parameters.
                                callTipText = @getFunctionCallTip({parameters : []}, 0)

                            if callTipText?
                                @removeCallTip()
                                @showCallTip(editor, newBufferPosition, callTipText)

                    getClassInfoPromises = []

                    for type in types
                        getClassInfoPromises.push @service.getClassInfo(type)

                    return Promise.all(getClassInfoPromises).then(successHandler, failureHandler)

                @service.deduceTypes(callStack, editor.getPath(), editor.getBuffer().getText(), offset).then(
                    deduceTypesSuccessHandler,
                    failureHandler
                )

            else
              successHandler = (globalFunctions) =>
                  if itemName[0] != '\\'
                      itemName = '\\' + itemName

                  if itemName of globalFunctions
                      callTipText = @getFunctionCallTip(globalFunctions[itemName], invocationInfo.argumentIndex)

                      @removeCallTip()
                      @showCallTip(editor, newBufferPosition, callTipText)

              @service.getGlobalFunctions().then(successHandler, failureHandler)

        @service.getInvocationInfoAt(editor, newBufferPosition).then(getInvocationInfoHandler, failureHandler)

    ###*
     * Builds the call tip for a PHP function or method.
     *
     * @param {array}       info                 Information about the function or method.
     * @param {number|null} activeArgumentNumber The number (starting from 0) of the argument that needs to be
     *                                           highlighted. Set to null to highlight nothing.
     *
     * @return {string}
    ###
    getFunctionCallTip: (info, activeArgumentNumber = null) ->
        return '(No parameters)' if info.parameters.length == 0

        body = ''

        # isInOptionalList = false

        for param, index in info.parameters
            isCurrentArgument = false

            if activeArgumentNumber == index
                isCurrentArgument = true

            else if activeArgumentNumber > index and param.isVariadic
                isCurrentArgument = true

            # body += '['   if param.isOptional and not isInOptionalList
            body += ', '  if index != 0
            body += '<span class="php-integrator-call-tip-inactive-argument">' if not isCurrentArgument

            if param.types.length > 0
                body += '<em>'
                body += (param.types.map((type) -> return type.type).join('|') + ' ')
                body += '</em>'

            body += '<strong>'
            body += '...' if param.isVariadic
            body += '&'   if param.isReference
            body += '$' + param.name
            body += '</strong>'

            if param.defaultValue
                body += ' '
                body += '<span class="keystroke php-integrator-call-tip-default-value">'
                body += param.defaultValue
                body += '</span>'

            body += '</span>' if not isCurrentArgument
            # body += ']'  if param.isOptional and index == (info.parameters.length - 1)

            # isInOptionalList = param.isOptional

        return body
