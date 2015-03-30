app = angular.module('autonomyApp', [
    'ngRoute',
    'Navigation',
    'Login',
    'Video'
])

.service('Authentication', [
    ->
        getCurrentUser: ->
            {
                name: 'DemoUser',
                id: 1,
                loggedIn: true,
                permissions:
                  StartCall: true
                  EndCall: true
                  ListShops: true
                  ListEmployees: true
            }
])

.service('Authorization', [
    'Authentication',
    (authentication) ->
        authorize: (loginRequired = false, permissions = []) ->
            user = authentication.getCurrentUser()

            authorizationResult =
                failedLogin: false
                failedPermissions: false
                missingPermissions: []

            if loginRequired && !user.loggedIn
                authorizationResult.failedLogin = true

            if _.difference(permissions, _.keys(user.permissions)).length > 0
                authorizationResult.failedPermissions = true
                authorizationResult.missingPermissions = _.difference(permissions, _.keys(user.permissions))

            return authorizationResult
])

.run([
    '$rootScope',
    '$location',
    'Authorization',
    ($rootScope, $location, authorization) ->
        $rootScope.$on('$routeChangeStart', (event, next) ->
            if !next.access
                return

            authorizationState = authorization.authorize(next.access.loginRequired, next.access.permissions)

            if authorizationState.failedLogin
                console.log('login required', authorizationState)
                event.preventDefault()
                $rootScope.$evalAsync(->
                    $location.path('/login');
                );

                return

            if authorizationState.failedPermissions
                console.log('missing permissions', authorizationState)
                event.preventDefault()
                return
        )
])

.config([
    '$routeProvider',
    '$locationProvider',
    ($routeProvider, $locationProvider) ->
        $routeProvider
          .when('/video', {
              templateUrl: 'views/modules/video/video.html',
              access: {
                  loginRequired: true,
                  permissions: ['StartCall', 'EndCall']
              }
          })
          .when('/login', {
              templateUrl: 'views/modules/login/login.html',
              controller:  'loginController'
          })
          .otherwise({
              redirectTo: '/login'
          })

        $locationProvider.html5Mode(true)
])
