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
                apiKey: 45214212
                sessionId: '1_MX40NTIxNDIxMn5-MTQzMzA5NzIxODA2MX5PN1ZLVGNlS1I2Yzc5STJWM3NuUGFiaTZ-fg'
                token: 'T1==cGFydG5lcl9pZD00NTIxNDIxMiZzaWc9ZmVkYTQ5ZDY3ODk0MGUxZWQ0OWI2NWNmM2ZlN2M5YmViZjJhYzA1ZTpyb2xlPXB1Ymxpc2hlciZzZXNzaW9uX2lkPTFfTVg0ME5USXhOREl4TW41LU1UUXpNekE1TnpJeE9EQTJNWDVQTjFaTFZHTmxTMUkyWXpjNVNUSldNM051VUdGaWFUWi1mZyZjcmVhdGVfdGltZT0xNDMzMDk3MjIyJm5vbmNlPTAuMzA5ODAxMzk5NzE1NjU0OCZleHBpcmVfdGltZT0xNDM1Njg4OTA5JmNvbm5lY3Rpb25fZGF0YT0='
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
                calculateVideoHeight: ->
                    return $(window).innerHeight() - $('nav').outerHeight() - $('#menu_controller').outerHeight()

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
                    server.session.connect(server.token, (error) ->
                        if (error)
                            console.log("Error connecting: ", error.code, error.message);
                            return

                        if server.session.capabilities.publish != 1
                            console.log('publish not available')
                            return

                        pubOptions = {
                            publishVideo: false, #disable the video stream
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
                    server.createSession().success(->
                        if OT.checkSystemRequirements() != 1
                            console.log('v', 'System requirements failed')
                            return

                        console.log('v', 'session created')
                        server.session = OT.initSession(server.apiKey, server.sessionId)
                        videoController.setupHost()
                    )

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
                        console.log("streamCreated executed")
                        server.guestAudioSubscriber = server.session.subscribe(streamCreatedEvent.stream, 'audio');
                    )

                    server.session.on("sessionDestroyed", (stream) ->
                        console.log("sessionDestroyed executed")
                    )

                    videoController.publishGuest()

                joinCall: ->
                    console.log('v', 'join call')
                    server.createSession().success(->
                        if OT.checkSystemRequirements() != 1
                            console.log('v', 'System requirements failed')
                            return

                        server.session = OT.initSession(server.apiKey, server.sessionId)
                        videoController.setupGuest()
                    )
            }

            $scope.stopCall = () ->
                $scope.onAir = false
                videoController.disconnect(server)

            $scope.startCall = ->
                $scope.onAir = true
                $scope.type = 'host'
                videoController.startCall()

            $scope.joinCall = ->
                $scope.onAir = true
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
