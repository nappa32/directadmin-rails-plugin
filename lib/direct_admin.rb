# Copyright (c) 2008 Voxxit, LLC
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module DirectAdmin #:nodoc:
  
  class MissingInformationError < StandardError; end #:nodoc:
  class DirectAdminError < StandardError; end #:nodoc:
  
  # Provides access to DirectAdmin's API
  class Base

    VERSION = "0.1"
    
	  # Defines the required parameters to interface with DA
  	REQUIRED_OPTIONS = {:base   => [:username, :password, :host, :port, :ssl, :failure_email],
  	                    :do     => [:command]}

  	attr_accessor :username,
                  :password,
                  :host,
                  :port,
                  :ssl,
                  :failure_email

  	# Initializes the DirectAdmin::Base class, setting defaults where necessary.
    # 
    #  da = DirectAdmin::Base.new(options = {})
    #
    # === Example:
    #   da = DirectAdmin::Base.new(:username      => USERNAME,
    #                              :password	    => PASSWORD,
    #                              :host          => HOST,
  	#							                 :port          => PORT,
  	#							                 :ssl           => SSL,
  	#                              :failure_email => FAILURE_EMAIL)
    #
    # === Required options for new
    #   :username       - Your DirectAdmin administrator username
    #   :password       - Your DirectAdmin administrator password
    #   :host           - DirectAdmin's hostname
  	#   :port           - DirectAdmin's port number
  	#   :ssl            - Enable or disable SSL. Defaults to false!
  	#   :failure_email  - E-mail address to send failure messages to
  	def initialize(options = {})
  	  check_required_options(:base, options)

  	  @username			  = options[:username]
  	  @password			  = options[:password]
  	  @host				    = options[:host]
  	  @ssl				    = options[:ssl]           || false
  	  @failure_email	= options[:failure_email]
  	end

    # Completes a command on the DirectAdmin server.
    #
    #  > dadmin = DirectAdmin::Base.new(options)
    #  > create = dadmin.do(options = {})
    #
    # === Required options for do
    #   :command      - Command you wish to run on the server. (See: http://directadmin.com/api.html)
    #   :formdata     - Required form data. (See below.)
    #
    # === Example:
    #   create = dadmin.do(:command => "CMD_API_SHOW_ALL_USERS)
    # 
    # === Optional form data
    # In order to complete this command, you may need to supply the
    # following form data as a hash in a POST request, as in the 
    # following example:
    #
    #  form_data = {:action => 'create',
    #               :add => 'Submit',
    #               :username => 'sampleuser',
    #               :email => 'sample@email.com',
    #               :passwd => 'sample_Password',
    #               :passwd2 => 'sample_Password',
    #               :domain => 'sample.com',
    #               :package => 'samplePackage',
    #               :ip => '10.0.0.0',
    #               :notify => 'no'}
    
  	def do(options = {})
  	  check_required_options(:do, options)
  	  
  	  @command = options[:command]
      
      # For POST requests..
      if options[:formdata]
        url = URI.parse(@host + @command)
        req = Net::HTTP::Post.new(url.path)
        req.basic_auth @username, @password
        req.set_form_data(options[:formdata])
        @response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
      
        if @response
    	    # @response.code = 200 | 404 | 500, etc.
      	  # @response.body = *text of returned page*
      	  return @response
    	  else
    	    raise DirectAdminError.new("Unable to connect to DirectAdmin.")
    	  end
      else
        # Nothing yet
      end
  	  
  	end

    # OLD *** Function to create a new service account on the server...
    #def create(username, email, password, domain_name, package_name, ip)

      ## Look at CMD_API_ACCOUNT_USER
      ## Might use that instead of CMD_ACCOUNT_USER (gives 0 or 1 error messages)

      #connect("/CMD_ACCOUNT_USER")
      #@request = Net::HTTP::Post.new(@url.path)
      #set_login

      #@request.form_data = [
      #  "action" => "create",
      #  "add" => "Submit",
      #  "username" => username,
      #  "email" => email,
      #  "passwd" => password,
      #  "passwd2" => passwd,
      #  "domain" => domain_name,
      #  "package" => package_name,
      #  "ip" => ip,
      #  "notify" => "no"
      #]

      #@result = Net::HTTP.new(@url.host).start {|http| 
      #  http.request(@request)
      #}

      # Error checking
      #case @result
      #when Net::HTTPSuccess
      #  if @result.include? "Domain Created Successfully"
      #    # Success! Decide what to do here once we test..
      #  elsif !@result.include? "Domain Created Successfully"
      #    # All connected, but it wasn't created successfully
      #    Notifier.deliver_error_message("[DIRECTADMIN] Client Creation Failed", "A failure occurred while logging in to the DirectAdmin server. Please check to make sure the package exists on the server, that the username is 4-8 characters long and that the e-mail address and domain name are correctly formatted. Also, make sure that the chosen IP address is available on the server and that the password doesn't contain any illegal characters.")
      #  elsif @result.include? "Please enter your Username and Password"
      #    # Login failed
      #    Notifier.deliver_error_message(LOGIN_ERR_SUBJECT, LOGIN_ERR)
      #  else
      #  end
      #else
      #  if @result == ""
      #    # Connection failed
      #    Notifier.deliver_error_message(CONNECT_ERR_SUBJECT, CONNECT_ERR)
      #  end
      #end
    #end
	
	  private
      # Checks the supplied options for a given method or field and throws an exception if anything is missing
      def check_required_options(option_set_name, options = {})
        required_options = REQUIRED_OPTIONS[option_set_name]
        missing = []
        required_options.each{|option| missing << option if options[option].nil?}

        unless missing.empty?
          raise MissingInformationError.new("Missing #{missing.collect{|m| ":#{m}"}.join(', ')}")
        end
      end

    end
  
end