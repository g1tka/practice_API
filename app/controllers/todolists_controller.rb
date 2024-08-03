class TodolistsController < ApplicationController
  def new
    @list = List.new
  end

  def create
    @list = List.new(list_params)
    # 以下score追記(language)
    @list.score = Language.get_data(list_params[:body])
    # 以下tag部分追記(vision)
    base64_image = Vision.get_base64_image(list_params[:image])
    tags = Vision.get_image_data(base64_image)
    colors = Vision.analyze_image(base64_image)
    if @list.save
      # 投稿した画像を Vision.get_image_data(list_params[:image]) でAPI側に渡し、そこから返ってきた値をもとに、タグを作成しています。
      tags.each do |tag|
        @list.tags.create(name: tag)
      end
      @list.colors.create(colors)
      # # 色解析用の追記
      # analyze_image(@list.image) if @list.image.attached?
      
      # analyze_imageメソッド(画像解析)を実行。analyze_imageメソッドはモデルに定義。
      # uploaded_image_path = params[:list][:image].tempfile.path
      redirect_to todolist_path(@list.id)
    else
      render :new
    end
  end

  def index
    @lists = List.all
  end

  def show
    @list = List.find(params[:id])
  end

  def edit
    @list = List.find(params[:id])
  end

  def update
    list = List.find(params[:id])
    list.update(list_params)
    redirect_to todolist_path(list.id)
  end

  def destroy
    list = List.find(params[:id])
    list.destroy
    redirect_to todolists_path
  end

  private

  def list_params
    params.require(:list).permit(:title, :body, :image)
  end

  def analyze_image(image)
    # Convert ActiveStorage::Blob to a file path
    image_path = Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
    # For cloud storage, you might need to download the file or use the signed URL.
    detect_labels(image_path)
  end

  def detect_labels(image_url)
    vision = Google::Cloud::Vision.image_annotator
    response = vision.label_detection image: image_url
    response.responses.each do |res|
      res.label_annotations.each do |label|
        Rails.logger.info "Label: #{label.description}, Score: #{label.score}"
      end
    end
  end

end
