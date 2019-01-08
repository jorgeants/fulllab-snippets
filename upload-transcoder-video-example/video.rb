# Video Model
class Video < ApplicationRecord
	include VideoUploader::Attachment.new(:video)
  include FileUploader::Attachment.new(:file)

	enum status: [ :unprocessed, :processing, :processed, :error ]

  belongs_to :discipline
  belongs_to :course

  def status_icon
  	"<span class='status #{self.status}'></span>".html_safe
  end

  CONST_PUBLISHED = {
    true => "yes_",
    false => "no_"
  }

  def published_label
    I18n.t(CONST_PUBLISHED[self.published])
  end

  def published_icon
  	icon = self.published ? "eye-open" : "eye-close"
  	"<span class='published glyphicon glyphicon-#{icon}' data-toggle='tooltip' data-placement='bottom' title='#{self.published_label}'></span>".html_safe
  end

  def streaming_playlist_url_complete
    # Aws::CF::Signer.sign_url("#{ENV['AWS_CLOUD_FRONT_HOST']}/#{self.streaming_playlist_url}")
    "#{ENV['AWS_CLOUD_FRONT_HOST']}/#{self.streaming_playlist_url}"
  end

  def file_icon
    if !self.file.nil?
      "<span style='color:#000' class='glyphicon glyphicon-paperclip' data-toggle='tooltip' data-placement='bottom' title='Arquivo existente'></span>".html_safe
    end
  end
end


# Video Controller
class VideosController < ApplicationController
	before_action :set_video, only: [:show, :edit, :update, :destroy, :upload, :update_video_after_upload]

	# GET /videos
	def index
		@videos = Video.paginate(:page => params[:page], :per_page => 30).order('created_at DESC')
	end

	# POST /videos
	# POST /videos.json
	def create
	  @video = Video.new(video_params)
	  @video.status = :unprocessed

	  respond_to do |format|
	    if @video.save
	      format.html { redirect_to upload_video_path(id: @video.id), notice: 'Video was successfully created.' }
	      format.json { render :show, status: :created, location: @video }
	    else
	      format.html { render :new }
	      format.json { render json: @video.errors, status: :unprocessable_entity }
	    end
	  end
	end

	# PATCH/PUT /videos/1
	# PATCH/PUT /videos/1.json
	def update
	  respond_to do |format|
	    if @video.update(video_params)
	      format.html { redirect_to videos_path, notice: 'Video was successfully updated.' }
	      # format.json { render :show, status: :ok, location: @video }
	    else
	      format.html { render :edit }
	      format.json { render json: @video.errors, status: :unprocessable_entity }
	    end
	  end
	end

	def destroy
	  @video.destroy
	  respond_to do |format|
	    format.html { redirect_to videos_url, notice: 'Vídeo excluído com sucesso.' }
	    format.json { head :no_content }
	  end
	end

	# GET /videos/:id/disciplines/:id_discipline/videos/:id_video/upload
	def upload

	end

	# POST /videos/:id/videos/:id_discipline/videos/:id_video/upload
	def update_video_after_upload
	  @video.status = :processing
	  respond_to do |format|
	    if @video.update(upload_params)
	      video_data = JSON.parse(@video.video_data)
	      input_key_video = [video_data["storage"], video_data["id"]].compact.join("/")

	      transcoder = Processor.new(input_key_video: input_key_video, video_id: @video.id)
	      transcoder.send_job

	      format.json { render json: { video: @video, redirect_url: videos_path }, status: :created }
	    else
	      format.json { render json: @video.errors, status: :unprocessable_entity }
	    end
	  end
	end

	private

	def set_video
	  @video = Video.find(params[:id])
	end

	def video_params
	  params.require(:video).permit(:name, :body, :discipline_id, :course_id, :status, :published, :file)
	end

	def upload_params
	  params.require(:video).permit(:video, :video_url, :status, :published)
	end
end
