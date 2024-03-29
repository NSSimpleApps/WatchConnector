Pod::Spec.new do |s|
    s.name         = "WatchConnector"
    s.version      = "1.4"
    s.summary      = "WatchConnector is a tool for more convenient interaction between Watch and Phone."
    s.description  = "WatchConnector is a tool for more convenient interaction between Watch and Phone. Activate WCSession during the app launch. You can listen to message, send message and update context without reassinging WCSession delegate. See the README"
    s.homepage     = "https://github.com/NSSimpleApps/WatchConnector"
    s.license      = { :type => 'MIT', :file => 'LICENSE' }
    s.author       = { 'NSSimpleApps, Sergey Poluyanov' => 'ns.simple.apps@gmail.com' }
    s.source       = { :git => "https://github.com/NSSimpleApps/WatchConnector.git", :tag => s.version.to_s }
    s.requires_arc = true
    s.swift_version = '5.7'

    s.platform                  = :ios, '11.0', :watchos, '4.0'

    s.ios.deployment_target     = '11.0'
    s.watchos.deployment_target     = '4.0'
    s.source_files = "Source/WatchConnector.swift"

end

