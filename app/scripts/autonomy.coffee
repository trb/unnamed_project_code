app = angular.module('autonomyApp', [
    'ngRoute',
    'Login',
    'Video'
])

.config(['$routeProvider',
    ($routeProvider) ->
        $routeProvider
        .when('/video', {
            templateUrl: 'views/modules/video/video.html',
            controller: 'videoController'
        })
        .when('/login', {
            templateUrl: 'views/modules/login/login.html',
            controller:  'loginController'
        })
        .otherwise({
            redirectTo: '/login'
        })
])
