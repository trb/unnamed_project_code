video = angular.module 'Video', []

video.directive('videoPlayer', [
    '$http',
    '$location',
    ($http, $location) ->
        restrict: 'E',
        templateUrl: 'views/modules/video/videoPlayer.html',
        link: ($scope) ->
            $scope.onAir = false;

            server = {
                apiKey: '45174472'
                sessionId: '1_MX40NTE3NDQ3Mn5-MTQzNTAxMTk0MTM1NH5OeG9iOTI0RFFYUTZsVERsQStDeUtLNDR-fg'
                token: 'T1==cGFydG5lcl9pZD00NTE3NDQ3MiZzaWc9NGVmMGVjZWNkNzRiYTJkMDliZjNlYWM1OWYyYzlkMjIxY2Q4NGI0Mzpyb2xlPXB1Ymxpc2hlciZzZXNzaW9uX2lkPTFfTVg0ME5URTNORFEzTW41LU1UUXpOVEF4TVRrME1UTTFOSDVPZUc5aU9USTBSRkZZVVRac1ZFUnNRU3REZVV0TE5EUi1mZyZjcmVhdGVfdGltZT0xNDM1MDExOTQ1Jm5vbmNlPTAuOTMxNTExNDUxNTUyNzA1MSZleHBpcmVfdGltZT0xNDM3NjAzOTM3JmNvbm5lY3Rpb25fZGF0YT0='
                session: {}

                hostVideoAndAudioSubscriber: null
                hostAudioPublisher: null

                guestAudioSubscriber: null
                guestVideoAndAudioPublisher: null

                createSession: ->
                    request = {
                        method: 'POST',
                        url: 'https://api.opentok.com/session/create',
                        headers: {
                            'X-TB-PARTNER-AUTH': this.apiKey + ':3beb94ec2b0ee7cdf64b42caaf6120baf543129b'
                        }
                        transformResponse: (data) ->
                            x2js = new X2JS()
                            json = x2js.xml_str2json(data)
                    }

                    $http(request)
            }

            videoController = {
                onAir: ->
                    $('nav').css('display', 'none')
                    $('#menu_controller').css('display', 'none')
                    $("#video_player").css({ position: 'fixed' })

                offAir: ->
                    $('nav').css('display', 'block')
                    $('#menu_controller').css('display', 'block')
                    $("#video_player").css({ position: 'relative' })

                calculateVideoHeight: ->
                    return $(window).innerHeight()

                calculateVideoWidth: ->
                    return $('#video').innerWidth()

                disconnect: (server) ->
                    if server.hostVideoAndAudioSubscriber
                        server.session.unsubscribe(server.hostVideoAndAudioSubscriber)

                    if server.hostAudioPublisher
                        server.session.unpublish(server.hostAudioPublisher)

                    if server.guestAudioSubscriber
                        server.session.unsubscribe(server.guestAudioSubscriber)

                    if server.guestVideoAndAudioPublisher
                        server.session.unpublish(server.guestVideoAndAudioPublisher)

                publishHost: ->
#                    this is how we would allow users to set their devices
#
#                    element = document.querySelector('#hardware-setup');
#
#                    options = {
#                        insertMode: 'append'
#                    };
#
#                    component = createOpentokHardwareSetupComponent(document.querySelector('#hardware-setup'), options, (error) ->
#                        if (error)
#                            console.error('Error: ', error);
#                            element.innerHTML = '<strong>Error getting devices</strong>: '
#                            error.message
#                            return
#                    # Add a button to call component.destroy() to close the component.
#                    )

                    server.session.connect(server.token, (error) ->
                        if (error)
                            console.log("Error connecting: ", error.code, error.message);
                            return

                        if server.session.capabilities.publish != 1
                            console.log('publish not available')
                            return

                        OT.getDevices((error, devices) ->
                            console.log('host devices', devices)

                            pubOptions = {
                                publishVideo: false, #disable the video stream
                                videoSource: null,
                                audioSource: devices[0],
                                height: 1,
                                width: 1
                            }

                            console.log('publisher options', pubOptions);

                            publisher = OT.initPublisher('audio', pubOptions, (error) ->
                                if (error)
                                    console.log('unable to publish')
                                else
                                    console.log('Publisher initialized.')
                            )

                            server.session.publish(publisher)

                            server.hostAudioPublisher = publisher
                        )
                    )

                setupHost: ->
                    console.log('v', 'setup host')
                    server.session.on("sessionConnected", (sessionConnectEvent) ->
                        console.log("sessionConnected executed")
                    )

                    server.session.on("streamCreated", (streamCreatedEvent) ->
                        console.log("streamCreated executed")
                        server.hostVideoAndAudioSubscriber = server.session.subscribe(
                            streamCreatedEvent.stream,
                            'video',
                                fitMode: 'contain'
                                height: videoController.calculateVideoHeight()
                                width: videoController.calculateVideoWidth()

                        )
                    )

                    server.session.on("sessionDestroyed", (stream) ->
                        console.log("sessionDestroyed executed")
                    )

                    videoController.publishHost()

                startCall: ->
                    console.log('v', 'start call')
#                    server.createSession().success(->
                    if OT.checkSystemRequirements() != 1
                        console.log('v', 'System requirements failed')
                        return

                    console.log('v', 'session created')
                    server.session = OT.initSession(server.apiKey, server.sessionId)
                    videoController.setupHost()
#                    )

                publishGuest: ->
                    server.session.connect(server.token, (error) ->
                        if (error)
                            console.log("Error connecting: ", error.code, error.message)
                            return

                        console.log("Connected to the session.")
                        if (server.session.capabilities.publish != 1)
                            console.log('publish not available')
                            return

                        console.log('can publish');
                        OT.getDevices((error, devices) ->
                            audioDevices = []
                            videoDevices = []

                            console.log('v', 'guestPublish', arguments)
                            $scope.devices = devices
                            $scope.$apply()

                            audioInputDevices = devices.filter((element) ->
                                return element.kind == "audioInput"
                            )
                            videoInputDevices = devices.filter((element) ->
                                return element.kind == "videoInput"
                            )
                            for device in audioInputDevices
                                audioDevices.push(device.deviceId)
                                console.log("audio input device: ", device.deviceId)

                            for device in videoInputDevices
                                videoDevices.push(device.deviceId)
                                console.log("video input device: ", device.deviceId)

                            pubOptions = {
                                #audioSource: audioDevices[1],
                                videoSource: videoDevices[1], #second camera on phone, will need to be able to select
                                mirror: false,
                                resolution: '1280x720',
                                frameRate: 30,
                                height: videoController.calculateVideoHeight(),
                                width: videoController.calculateVideoWidth()
                            }

                            console.log('publisher options', pubOptions)

                            server.guestVideoAndAudioPublisher = OT.initPublisher('video', pubOptions, (error) ->
                                if (error)
                                    # The client cannot publish.
                                    # You may want to notify the user.
                                    console.log('unable to publish')
                                else
                                    console.log('Publisher initialized.')
                            )

                            server.session.publish(server.guestVideoAndAudioPublisher)
                        )
                    )

                setupGuest: ->
                    server.session.on("sessionConnected", (sessionConnectEvent) ->
                        console.log("sessionConnected executed")
                    )

                    server.session.on("streamCreated", (streamCreatedEvent) ->
                        console.log("streamCreated executed, listening to host audio")
                        server.guestAudioSubscriber = server.session.subscribe(
                            streamCreatedEvent.stream,
                            'audio',
                                subscribeToAudio: true
                                subscribeToVideo: false
                        );
                        console.log('subscriber, guest audio', server.guestAudioSubscriber);
                    )

                    server.session.on("sessionDestroyed", (stream) ->
                        console.log("sessionDestroyed executed")
                    )

                    videoController.publishGuest()

                joinCall: ->
                    console.log('v', 'join call')
#                    server.createSession().success(->
                    if OT.checkSystemRequirements() != 1
                        console.log('v', 'System requirements failed')
                        return

                    server.session = OT.initSession(server.apiKey, server.sessionId)
                    videoController.setupGuest()
#                    )
            }

            $scope.$watch('onAir', (broadcasting) ->
                if broadcasting
                    videoController.onAir()
                else
                    videoController.offAir()
            )

            $scope.stopCall = () ->
                $scope.onAir = false
                videoController.disconnect(server)

            $scope.toggleSettings = ()->
                $scope.showSettings = !$scope.showSettings

            $scope.startCall = ->
                $scope.onAir = true
                $scope.showSettings = false
                $scope.type = 'host'
                videoController.startCall()

            $scope.joinCall = ->
                $scope.onAir = true
                $scope.showSettings = false
                $scope.type = 'guest'
                videoController.joinCall()

            checkAutoCallInterval = null
            checkAutoCall = ->
                if (window.OT)
                    if $location.search().call
                        $scope.startCall()

                    clearInterval(checkAutoCallInterval)

            checkAutoCallInterval = setInterval(checkAutoCall, 20)
])
