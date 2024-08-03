require "google/cloud/vision"

class GoogleVisionService
  def initialize
    @vision = Google::Cloud::Vision.image_annotator
  end

  def detect_labels(image_url)
    response = @vision.label_detection image: image_url
    labels = response.responses.flat_map do |res|
      res.label_annotations.map do |label|
        { description: label.description, score: label.score }
      end
    end
    labels
  end

  def analyze_image(uploaded_image_path)
    # APIキーを環境変数として渡す。
    api_key = ENV['GOOGLE_API_KEY']
    
    # Google Cloud Vision APIのエンドポイントを構築。
    uri = URI("https://vision.googleapis.com/v1/images:annotate?key=#{api_key}")
    
    # 渡された画像データをBase64にエンコードしてAPIに送れる形にする。
    image_data = Base64.strict_encode64(File.open(uploaded_image_path, 'rb').read)
    
    # 画像データと解析したい内容（今回は色情報が欲しいのでプロパティを選択）を指定
    body = {
     requests: [{
       image: {
         content: image_data
       },
       features: [{
         type: "IMAGE_PROPERTIES",
         maxResults: 10
       }]
     }]
    }.to_json
    
    # HTTPオブジェクトを使ってHTTPリクエストを作成。
    # POSTメソッド+ヘッダーに'Content-Type' => 'application/json'を指定。
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'application/json'})
    request.body = body
    
    # リクエストを送信→レスポンス受け取り。
    response = http.request(request)
    
    # レスポンスのHTTPステータスコードが200の場合、レスポンスボディから色情報を抽出。
    if response.code == '200'
     color_full_data = JSON.parse(response.body)['responses'][0]['imagePropertiesAnnotation']['dominantColors']['colors']
    else
     # エラーハンドリングの実装をここに記述
    end
  end

end