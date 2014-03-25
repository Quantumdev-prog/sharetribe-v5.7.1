class S3Uploader

  def initialize()
    @aws_access_key_id = APP_CONFIG.aws_access_key_id
    @aws_secret_access_key = APP_CONFIG.aws_secret_access_key
    @bucket = APP_CONFIG.s3_bucket_name
    @acl = "public-read"
    @expiration = 10.hours.from_now
    @max_file_size = 8.megabytes
  end

  def fields
    {
      :key => key,
      :acl => @acl,
      :policy => policy,
      :signature => signature,
      "AWSAccessKeyId" => @aws_access_key_id
    }
  end

  def url
    "https://s3.amazonaws.com/#{@bucket}/"
  end

  private

  def url_friendly_time
    Time.now.utc.strftime("%Y%m%dT%H%MZ")
  end

  def key
    "uploads/listing-images/#{url_friendly_time}-#{SecureRandom.hex}/${filename}"
  end

  def policy
    Base64.encode64(policy_data.to_json).gsub("\n", "")
  end

  def policy_data
    {
      expiration: @expiration.utc.iso8601,
      conditions: [
        ["starts-with", "$key", ""],
        ["starts-with", "$Content-Type", ""],
        ["content-length-range", 0, @max_file_size],
        {bucket: @bucket},
        {acl: @acl}
      ]
    }
  end

  def signature
    Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest::Digest.new('sha1'),
        @aws_secret_access_key, policy
      )
    ).gsub("\n", "")
  end
end