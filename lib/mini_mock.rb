class MiniMock
  RECORDINGS_PATH = 'mini_mock'
  DEFAULT_FILE = "mocks"

  class << self

    def record file_name=DEFAULT_FILE
      FileUtils.mkdir_p(RECORDINGS_PATH)
      @@file_name = file_name
      Typhoeus::Config.block_connection = false
      add_callback
      true
    end

    def replay file_name=DEFAULT_FILE
      Typhoeus::Config.block_connection = true
      remove_callback
      load "#{RECORDINGS_PATH}/#{file_name}.rb"
      true
    end

    def off
      Typhoeus::Config.block_connection = false
      remove_callback
      true
    end

    private
    def add_callback
      unless Typhoeus.on_complete.include?(AFTER_REQUEST_CALLBACK)
        Typhoeus.on_complete << AFTER_REQUEST_CALLBACK
      end
    end

    def remove_callback
      Typhoeus.on_complete.delete_if {|v| v == AFTER_REQUEST_CALLBACK }
    end

  end

  AFTER_REQUEST_CALLBACK = Proc.new do |response|
    code = <<~RUBY
      response = Typhoeus::Response.new(
        code: #{response.code},
        status_message: "#{response.status_message}",
        body: #{response.body.inspect},
        headers: #{response.headers},
        effective_url: #{response.effective_url.inspect},
        options: #{response.options.tap{|a| a[:debug_info] = ""}.inspect}
      )
      Typhoeus.stub(#{response.request.base_url.inspect}, #{response.request.original_options})
      .and_return(response)

    RUBY
    File.write "#{RECORDINGS_PATH}/#{@@file_name}.rb", code, mode: 'a+'
  end

end
