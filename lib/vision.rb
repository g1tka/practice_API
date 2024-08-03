require 'base64'
require 'json'
require 'net/https'

module Vision
  class << self
    def get_base64_image(image_file)
      # 画像をbase64にエンコード
      Base64.encode64(image_file.tempfile.read)
    end
    def get_image_data(base64_image)
      # APIのURL作成
      api_url = "https://vision.googleapis.com/v1/images:annotate?key=#{ENV['GOOGLE_API_KEY']}"

      # APIリクエスト用のJSONパラメータ
      params = {
        requests: [{
          image: {
            content: base64_image
          },
          features: [
            {
              type: 'LABEL_DETECTION'
            }
          ]
        }]
      }.to_json

      # Google Cloud Vision APIにリクエスト
      uri = URI.parse(api_url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      response = https.request(request, params)
      response_body = JSON.parse(response.body)
      # APIレスポンス出力
      if (error = response_body['responses'][0]['error']).present?
        raise error['message']
      else
        response_body['responses'][0]['labelAnnotations'].pluck('description').take(3)
      end
    end
    
    def analyze_image(base64_image)
      # APIキーを環境変数として渡す。
      api_url = "https://vision.googleapis.com/v1/images:annotate?key=#{ENV['GOOGLE_API_KEY']}"
      
      # 画像データと解析したい内容（今回は色情報が欲しいのでプロパティを選択）を指定
      params = {
       requests: [{
         image: {
           content: base64_image
         },
         features: [{
           type: "IMAGE_PROPERTIES",
           maxResults: 1
         }]
       }]
      }.to_json
      
      # HTTPオブジェクトを使ってHTTPリクエストを作成。
      # POSTメソッド+ヘッダーに'Content-Type' => 'application/json'を指定。
      uri = URI.parse(api_url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'application/json'})
      response = https.request(request, params)
      response_body = JSON.parse(response.body)
      
      # リクエストを送信→レスポンス受け取り。
      
      # レスポンスのHTTPステータスコードが200の場合、レスポンスボディから色情報を抽出。
      if response.code == '200'
        color_full_data = JSON.parse(response.body)['responses'][0]['imagePropertiesAnnotation']['dominantColors']['colors']
        color_full_data.map do |color|
          {
            red: color["color"]["red"],
            green: color["color"]["green"],
            blue: color["color"]["blue"],
            score: color["score"],
            pixel_fraction: color["pixelFraction"]
          }
        end
      else
       # エラーハンドリングの実装をここに記述
      end
    end
  end
end