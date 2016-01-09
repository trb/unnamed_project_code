video = angular.module 'Video', ['ngCookies']

video.directive('videoPlayer', [
    '$http',
    '$location',
    '$cookies'
    ($http, $location, $cookies) ->
        restrict: 'E',
        templateUrl: 'views/modules/video/videoPlayer.html',
        link: ($scope) ->
            $scope.onAir = false;

            server = {
                apiKey: '45174472'
                sessionId: '1_MX40NTE3NDQ3Mn5-MTQ1MjI5OTY3MjM5OX5vK210L2F0MVJrSmx2enBGN0dmcFdaSFl-UH4'
                token: 'T1==cGFydG5lcl9pZD00NTE3NDQ3MiZzaWc9Y2UwNTUxNTAwZjMwMGJmZjMzY2NmNjI2ZTY2MjI2N2M1ZjJhNGE3MTpyb2xlPW1vZGVyYXRvciZzZXNzaW9uX2lkPTFfTVg0ME5URTNORFEzTW41LU1UUTFNakk1T1RZM01qTTVPWDV2SzIxMEwyRjBNVkpyU214MmVuQkdOMGRtY0ZkYVNGbC1VSDQmY3JlYXRlX3RpbWU9MTQ1MjI5OTY3NiZub25jZT0wLjUwNzI4MzkyNjUwNTAxODImZXhwaXJlX3RpbWU9MTQ1NDg5MTYwMSZjb25uZWN0aW9uX2RhdGE9'
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

            deviceController = {
                deviceSettings: {
                    audioDevices: [],
                    videoDevices: [],
                    currentVideoDevice: $cookies.get('video_device'),
                    currentAudioDevice: $cookies.get('audio_device')
                }

                setupDevices: (devices) ->
                    #console.log('host devices', devices)

                    audioInputDevices = devices.filter((element) ->
                        return element.kind == "audioInput"
                    )
                    videoInputDevices = devices.filter((element) ->
                        return element.kind == "videoInput"
                    )
                    for device in audioInputDevices
                        this.deviceSettings.audioDevices.push(device.deviceId)
                        #console.log("audio input device: ", device.deviceId)

                    for device in videoInputDevices
                        this.deviceSettings.videoDevices.push(device.deviceId)
                        #console.log("video input device: ", device.deviceId)

                    this.deviceSettings.currentAudioDevice = $cookies.get('audio_device') || this.deviceSettings.audioDevices[0]
                    this.deviceSettings.currentVideoDevice = $cookies.get('video_device') || this.deviceSettings.videoDevices[1]

                    #console.log('i use this audio', this.deviceSettings.currentAudioDevice);
                    return this.deviceSettings

                isLastDevice: (devices, current)->
                    #if devices[devices.length-1] == current
                        #console.log('last device');
                    devices[devices.length-1] == current

                getNextAudioDevice: ->
                    if !this.isLastDevice(this.deviceSettings.audioDevices, this.deviceSettings.currentAudioDevice)
                        return this.deviceSettings.audioDevices[this.deviceSettings.audioDevices.indexOf(this.deviceSettings.currentAudioDevice) + 1]
                    else
                        return this.deviceSettings.audioDevices[0];
                getNextVideoDevice: ->
                    if !this.isLastDevice(this.deviceSettings.videoDevices, this.deviceSettings.currentVideoDevice)
                        return this.deviceSettings.videoDevices[this.deviceSettings.videoDevices.indexOf(this.deviceSettings.currentVideoDevice) + 1]
                    else
                        return this.deviceSettings.videoDevices[0];
            }

            videoController = {
                publisher: null

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

                enableDeviceSelectors: (devices) ->
                    $scope.hasMultipleVideoDevices = devices.videoDevices.length > 1
                    $scope.hasMultipleAudioDevices = devices.audioDevices.length > 1
                    $scope.$apply();

                disconnect: (server) ->
                    if server.hostVideoAndAudioSubscriber
                        server.session.unsubscribe(server.hostVideoAndAudioSubscriber)

                    if server.hostAudioPublisher
                        server.session.unpublish(server.hostAudioPublisher)

                    if server.guestAudioSubscriber
                        server.session.unsubscribe(server.guestAudioSubscriber)

                    if server.guestVideoAndAudioPublisher
                        server.session.unpublish(server.guestVideoAndAudioPublisher)

                    document.location.reload(); # workaround to be able to call again, should be able to publish again without load.

                publishHost: ->
                    server.session.connect(server.token, (error) ->
                        if (error)
                            #console.log("Error connecting: ", error.code, error.message);
                            return

                        if server.session.capabilities.publish != 1
                            #console.log('publish not available')
                            return

                        OT.getDevices((error, devices) ->

                            # load available input/output devices and enable toggle in interface
                            videoController.enableDeviceSelectors(deviceController.setupDevices(devices));

                            #console.log(deviceController.deviceSettings.currentAudioDevice);
                            pubOptions = {
                                publishVideo: false, #disable the video stream
                                videoSource: null,
                                audioSource: deviceController.deviceSettings.currentAudioDevice,
                                height: 1,
                                width: 1
                            }

                            #console.log('publisher options', pubOptions);

                            videoController.publisher = OT.initPublisher('audio', pubOptions, (error) ->
                                if (error)
                                    #console.log('unable to publish')
                                else
                                    #console.log('Publisher initialized.')
                            )

                            server.session.publish(videoController.publisher)

                            server.hostAudioPublisher = videoController.publisher
                        )
                    )

                setupHost: ->
                    #console.log('v', 'setup host')
                    server.session.on("sessionConnected", (sessionConnectEvent) ->
                        #console.log("sessionConnected executed")
                    )

                    server.session.on("streamCreated", (streamCreatedEvent) ->
                        #console.log("streamCreated executed")
                        server.hostVideoAndAudioSubscriber = server.session.subscribe(
                            streamCreatedEvent.stream,
                            'video',
                                fitMode: 'contain'
                                height: videoController.calculateVideoHeight()
                                width: videoController.calculateVideoWidth()

                        )
                    )

                    server.session.on("sessionDestroyed", (stream) ->
                        #console.log("sessionDestroyed executed")
                    )

                    videoController.publishHost()

                startCall: ->
                    #console.log('v', 'start call')
#                    server.createSession().success(->
                    if OT.checkSystemRequirements() != 1
                        #console.log('v', 'System requirements failed')
                        return

                    #console.log('v', 'session created')
                    server.session = OT.initSession(server.apiKey, server.sessionId)
                    videoController.setupHost()
#                    )

                publishGuest: ->
                    server.session.connect(server.token, (error) ->
                        if (error)
                            #console.log("Error connecting: ", error.code, error.message)
                            return

                        #console.log("Connected to the session.")
                        if (server.session.capabilities.publish != 1)
                            #console.log('publish not available')
                            return

                        #console.log('can publish');
                        OT.getDevices((error, devices) ->
                            #console.log('v', 'guestPublish', arguments)

                            # load available input/output devices and enable toggle in interface
                            videoController.enableDeviceSelectors(deviceController.setupDevices(devices));

                            pubOptions = {
                                audioSource: deviceController.deviceSettings.currentAudioDevice,
                                videoSource: deviceController.deviceSettings.currentVideoDevice, #second camera on phone, will need to be able to select
                                mirror: false,
                                resolution: '1280x720',
                                frameRate: 30,
                                height: videoController.calculateVideoHeight(),
                                width: videoController.calculateVideoWidth()
                            }

                            #console.log('publisher options', pubOptions)

                            this.publisher = server.guestVideoAndAudioPublisher = OT.initPublisher('video', pubOptions, (error) ->
                                if (error)
                                    # The client cannot publish.
                                    # You may want to notify the user.
                                    #console.log('unable to publish')
                                else
                                    #console.log('Publisher initialized.')
                            )

                            server.session.publish(this.publisher)
                        )
                    )

                setupGuest: ->
                    server.session.on("sessionConnected", (sessionConnectEvent) ->
                        #console.log("sessionConnected executed")
                    )

                    server.session.on("streamCreated", (streamCreatedEvent) ->
                        #console.log("streamCreated executed, listening to host audio")
                        server.guestAudioSubscriber = server.session.subscribe(
                            streamCreatedEvent.stream,
                            'audio',
                                subscribeToAudio: true
                                subscribeToVideo: false
                        );
                        #console.log('subscriber, guest audio', server.guestAudioSubscriber);
                    )

                    server.session.on("sessionDestroyed", (stream) ->
                        #console.log("sessionDestroyed executed")
                    )

                    videoController.publishGuest()

                joinCall: ->
                    #console.log('v', 'join call')
                    if OT.checkSystemRequirements() != 1
                        #console.log('v', 'System requirements failed')
                        return

                    server.session = OT.initSession(server.apiKey, server.sessionId)
                    videoController.setupGuest()
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

            ### @todo the basic functions are now available but the UX is currently terrible

                the audio and video selectors allow you to change devices and save your device
                settings to a cookie, there is currently no feedback that your device has been
                changed and you need to reload the page after the change. This will break any
                calls in progress.

                There is a method that is currently unimplemented on the publisher that would
                make this a lot easier, it is only available on the mobile platforms.

                https://tokbox.com/developer/guides/audio-video/android/#select_camera

            ###

            $scope.switchAudioDevice = () ->
                deviceController.deviceSettings.currentAudioDevice = deviceController.getNextAudioDevice();
                $cookies.put('audio_device', deviceController.deviceSettings.currentAudioDevice);
                $scope.stopCall();

            $scope.switchVideoDevice = () ->
                deviceController.deviceSettings.currentVideoDevice = deviceController.getNextVideoDevice();
                $cookies.put('video_device', deviceController.deviceSettings.currentVideoDevice);
                $scope.stopCall();

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
