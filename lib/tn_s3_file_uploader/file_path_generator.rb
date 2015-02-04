require 'rubygems'

module TnS3FileUploader

  # Examples
  # partition = y=2014/m=06/d=18/h=18
  # minute_partition = 45
  # file_timestamp = 20140618184502
  # date = Wed Jun 18 18:50:02 UTC 2014

  # [ec2-user@ip-10-185-180-243 tmp]$ ./time.sh
  # partition = y=2014/m=06/d=18/h=18
  # minute_partition = 55
  # file_timestamp = 20140618185540
  # date = Wed Jun 18 19:03:40 UTC 2014
  class FilePathGenerator

    def initialize(time, options)
      #Find the last rotation window
      @options = options
      @time = previous_rotation_window(time)
    end


    # Makes datetime and macro substitutions for input file 'file', based on the s3_output_pattern option
    # Assumes input file 'file' and s3_output_pattern option are both valid.
    # This method removes the bucket (everything until the first '/', including the '/') from the s3_output_pattern
    # while applying the datetime/macro/substitutions
    def dest_full_path_for(file)

      output_file_pattern = remove_bucket(@options[:s3_output_pattern])

      # Time#strftime is removing '%' characters on our macros. Our macro substitution must run first
      subs = build_substitutions(file)
      replace_macros!(output_file_pattern, subs)

      substitute_datetime_macros(output_file_pattern)
    end

    private

    def remove_bucket(output_file_pattern)
      output_file_pattern.split('/')[1..-1].join('/')
    end

    # Makes the datetime substitutions on the give s3_output_pattern option
    # For example:
    #  Given s3_output_pattern y=%Y/m=%m/d=%d/h=%H
    #  and time: Thu Jun 12 23:57:49 UTC 2014
    #  it will produce the following folder structure: y=2014/m=06/d=12/h=23
    def substitute_datetime_macros(output_pattern)
      @time.strftime(output_pattern)
    end

    # Generates rounded off timestamp based on rotation_seconds
    def generate_file_timestamp
      @time.strftime('%Y%m%d%H%M%S')
    end

    def replace_macros!(output_file_pattern, subs)
      subs.each do |macro, sub|
        output_file_pattern.gsub!(macro, sub)
      end
    end

    # First tries to find local IP using UDPSocket technique.
    # In the event of a failure, we will revert to using the old
    # method of local ip retrieval.  In the event that both techniques
    # fail, we return a default value
    def local_ip
      resolve_ip = @options[:udp_resolve_ip]
      ip_address = nil
      
      unless resolve_ip.nil?
        ip_address = udp_resolve_ip(resolve_ip)
      end

      unless ip_address.nil? or valid_ip?(ip_address)
        ip_address = hostname_resolve_ip
      end

      unless valid_ip?(ip_address)
        ip_address = '0.0.0.0'
      end
      
      ip_address
    end

    # Finds public local IP by tracing a UDP route.
    # Note: This code does NOT make a connection or send any packets to the listed resolve_ip
    # UDP is a stateless protocol, the connect method makes
    # a system call to determine packet routing based on address and what interface it
    # should bind to. addr returns an array containing the family, local port and local address
    # The local address is the last element in the addr array.
    def udp_resolve_ip(resolve_ip)
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true

      UDPSocket.open do |s|
        s.connect resolve_ip, 1
        s.addr.last
      end
    ensure
      Socket.do_not_reverse_lookup = orig
    end
    
    def hostname_resolve_ip
      IPSocket.getaddress(Socket.gethostname)
    end

    def valid_ip?(resolve_ip)
      resolve_ip =~ /\d+\.\d+\.\d+\.\d+/
    end

    def build_substitutions(file)
      file_components = file.split('/').last.split('.')

      if file_components.size == 1
        file_name = file_components[0]
        file_extension = ''
      else
        file_name = file_components[0..-2].join('.')
        file_extension = file_components.last
      end
      
      ip_address = local_ip.gsub('.', '-')
      
      file_timestamp = generate_file_timestamp

      {
          '%{file-name}' => file_name,
          '%{file-timestamp}' => file_timestamp,
          '%{file-extension}' => file_extension,
          '%{ip-address}' => ip_address
      }
    end

    def previous_rotation_window(time)
      rotation_seconds = @options[:file_timestamp_resolution]
      t = time - rotation_seconds
      floored_seconds = (t.to_f / rotation_seconds).floor * rotation_seconds
      Time.at(floored_seconds).utc
    end
  end

end