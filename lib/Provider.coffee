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

            if invocationInfo.type == 'function'
                successHandler = (globalFunctions) =>
                    itemName = invocationInfo.name

                    if itemName[0] != '\\'
                        itemName = '\\' + itemName

                    if itemName of globalFunctions
                        callTipText = @getFunctionCallTip(globalFunctions[itemName], invocationInfo.argumentIndex)

                        @removeCallTip()
                        @showCallTip(editor, newBufferPosition, callTipText)

                return @service.getGlobalFunctions().then(successHandler, failureHandler)

            else if invocationInfo.type == 'method'
                methodName = invocationInfo.name

                offset = @service.getCharacterOffsetFromByteOffset(invocationInfo.offset, editor.getBuffer().getText())

                deduceTypesSuccessHandler = (types) =>
                    successHandler = (classInfoArray) =>
                        for classInfo in classInfoArray
                            callTipText = null

                            if invocationInfo.name of classInfo.methods
                                callTipText = @getFunctionCallTip(classInfo.methods[invocationInfo.name], invocationInfo.argumentIndex)

                            if callTipText?
                                @removeCallTip()
                                @showCallTip(editor, newBufferPosition, callTipText)

                    getClassInfoPromises = []

                    for type in types
                        getClassInfoPromises.push @service.getClassInfo(type)

                    return Promise.all(getClassInfoPromises).then(successHandler, failureHandler)

                return @service.deduceTypes(invocationInfo.expression, editor.getPath(), editor.getBuffer().getText(), offset, true).then(
                    deduceTypesSuccessHandler,
                    failureHandler
                )

            else if invocationInfo.type == 'instantiation'
                resolveTypeAtSuccessHandler = (fqcn) =>
                    successHandler = (classInfo) =>
                        callTipText = null

                        if '__construct' of classInfo.methods
                            callTipText = @getFunctionCallTip(classInfo.methods['__construct'], invocationInfo.argumentIndex)

                        else
                            # Not all classes have an explicit constructor, if none is specified, a public one
                            # exists, so pretend there are no parameters.
                            callTipText = @getFunctionCallTip({parameters : []}, 0)

                        if callTipText?
                            @removeCallTip()
                            @showCallTip(editor, newBufferPosition, callTipText)

                    return @service.getClassInfo(fqcn).then(successHandler, failureHandler)

                return @service.resolveTypeAt(editor, newBufferPosition, invocationInfo.expression, 'classlike').then(
                    resolveTypeAtSuccessHandler,
                    failureHandler
                )

        if @isValidBufferPosition(editor, newBufferPosition)
            @service.getInvocationInfoAt(editor, newBufferPosition).then(getInvocationInfoHandler, failureHandler)

    ###*
     * @param {TextEditor}  editor
     * @param {Point}       bufferPosition
     *
     * @return {Boolean}
    ###
    isValidBufferPosition: (editor, bufferPosition) ->
        scopeChain = editor.scopeDescriptorForBufferPosition(bufferPosition).getScopeChain()

        if scopeChain.indexOf('.comment') != -1
            return false

        return true

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
                body += (param.types.map((type) -> return type.type).join('|') + '&nbsp;')
                body += '</em>'

            body += '<strong>'
            body += '...' if param.isVariadic
            body += '&'   if param.isReference
            body += '$' + param.name
            body += '</strong>'

            if param.defaultValue
                body += '&nbsp;'
                body += '<span class="keystroke php-integrator-call-tip-default-value">'
                body += param.defaultValue
                body += '</span>'

            body += '</span>' if not isCurrentArgument
            # body += ']'  if param.isOptional and index == (info.parameters.length - 1)

            # isInOptionalList = param.isOptional

        return body
