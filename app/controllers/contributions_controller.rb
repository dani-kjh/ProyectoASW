class ContributionsController < ApplicationController
  before_action :set_contribution, only: [:show, :edit, :update, :destroy, :like, :dislike]
  before_action :authenticate_user!, only: [:new, :create, :edit, :update]

  # special actions on this actions because they are called by js and doesnt work fine, i dont know why
  # before_action :check_signed_in, only: [:like, :dislike]
  before_action :get_user_from_token, only: [:like, :dislike]

  skip_before_action :verify_authenticity_token, only: [:like, :dislike]

  # GET /contributions
  # GET /contributions.json
  def index
    @contributions = Contribution.where(contribution_type: "url").order(points: :desc)
  end

  # GET /contributions/1
  # GET /contributions/1.json
  def show
  end

  # GET /contributions/show_news
  def show_news
    @contributions = Contribution.all.order(created_at: :desc)
    render :index
  end

  def show_user
    @contributions = Contribution.where(user_id: params[:id])
    render :index
  end

  def show_ask
    @contributions = Contribution.where(contribution_type: "ask").order(points: :desc)
    render :index
  end
  # GET /contributions/new
  def new
    @contribution = Contribution.new
  end

  # GET /contributions/1/edit
  def edit
  end

  # POST /contributions
  # POST /contributions.json
  def create

    @contribution = ContributionServices::CreateContributionService.new(contribution_params).call

    if @contribution.url.blank?
      current_user.contributions << @contribution
      respond_to do |format|
        if current_user.save
          format.html { redirect_to show_news_contributions_url }
          format.json { render :show, status: :created, location: @contribution }
        else
          format.html { redirect_to new_contribution_path, alert: @contribution.errors.full_messages.join(', ') }
          format.json { render json: @contribution.errors, status: :unprocessable_entity }
        end
      end
    else
      @contribution_existing = Contribution.find_by_url(@contribution.url)
      respond_to do |format|
        if @contribution_existing.present?
          format.html { redirect_to @contribution_existing}
          format.json { render :show, status: :ok, location: @contribution }

        else
          if !@contribution.text.blank?
            @contribution_new = Contribution.new
            @contribution_new.url = @contribution.url
            @contribution_new.title = @contribution.title
            @contribution_new.user_id = @contribution.user_id
            @contribution_new.created_at = @contribution.created_at
            @contribution_new.updated_at = @contribution.updated_at
            @contribution_new.points = @contribution.points
            @contribution_new.contribution_type = @contribution.contribution_type

            current_user.contributions << @contribution_new


            current_user.comments.create({ :text => @contribution.text, :contribution_id => @contribution_new.id, :replayedComment_id => nil})
            @comment = @contribution_new.comments.create({ :text => @contribution.text, :contribution_id => @contribution_new.id, :replayedComment_id => nil})
            if current_user.save
              format.html { redirect_to @contribution_new }
              format.json { render :show, status: :created, location: @contribution_new}
            else
              format.html { redirect_to new_contribution_path, alert: @contribution_new.errors.full_messages.join(', ') }
              format.json { render json: @contribution_new.errors, status: :unprocessable_entity }
            end
          else
            current_user.contributions << @contribution
            if current_user.save
              format.html { redirect_to show_news_contributions_url }
              format.json { render :show, status: :created, location: @contribution }
            else
              format.html { redirect_to new_contribution_path, alert: @contribution.errors.full_messages.join(', ') }
              format.json { render json: @contribution.errors, status: :unprocessable_entity }
            end
          end
        end
      end
    end
  end


  # PATCH/PUT /contributions/1
  # PATCH/PUT /contributions/1.json
  def update
    respond_to do |format|
      if @contribution.update(contribution_params)
        format.html { redirect_to @contribution, notice: 'Contribution was successfully updated.' }
        format.json { render :show, status: :ok, location: @contribution }
      else
        format.html { render :edit }
        format.json { render json: @contribution.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contributions/1
  # DELETE /contributions/1.json
  def destroy
    @contribution.destroy
    respond_to do |format|
      format.html { redirect_to contributions_url, notice: 'Contribution was successfully destroyed.' }
      format.json { head :no_content }
    end
  end



  # TODO: add logic to check if user is logged in before let make vote
  def like
    begin
      if @user.nil?
        render json:{
          error: "You need to be logged in to vote",
          status: :unauthorized
        }, status: :unauthorized
      elsif @user.voted_contributions.include?(@contribution)
        render json:{
          error: "user already voted",
          status: :unprocessable_entity
        }, status: :unprocessable_entity
      elsif @contribution.nil?
        render json:{
          error: "contribution not found",
          status: :unprocessable_entity
        }, status: :unprocessable_entity
      else
        @contribution.points += 1
        if @contribution.save
          @user.voted_contributions << @contribution
          if @user.save
            render json:{
              message: "user voted",
              status: :ok
            }, status: :ok
          end
        else
          render json:{
            error: "error saving vote",
            status: :unprocessable_entity
          }, status: :unprocessable_entity
        end
      end
    rescue => e
      render json:{
        error: e.message,
        status: :unprocessable_entity
      }, status: :unprocessable_entity
    end
  end

  def dislike
    begin
      if @user.nil?
        render json:{
          error: "user not authorized",
          status: :unauthorized
        }, status: :unauthorized

      elsif !@user.voted_contributions.include?(@contribution)
        render json:{
          error: "user not voted yet",
          status: :unprocessable_entity
        }, status: :unprocessable_entity
      elsif @contribution.nil?
        render json:{
          error: "contribution not found",
          status: :unprocessable_entity
        }, status: :unprocessable_entity
      else
        @contribution.points -= 1

        if @contribution.save
          @user.voted_contributions.delete(@contribution)
          if @user.save
            render json:{
              message: "user unvoted",
              status: :ok
            }, status: :ok
          end
        else
          render json:{
            error: "user not unvoted",
            status: :unprocessable_entity
          }, status: :unprocessable_entity
        end
      end
    rescue => e
      render json:{
        error: e.message,
        status: :unprocessable_entity
      }, status: :unprocessable_entity
    end
  end

  def show_upvoted_contributions
    begin
      user = User.find(params[:id])
      @contributions = user.voted_contributions
      puts @contributions.inspect
      respond_to do |format|
        if @contributions
          format.html { render :show_news }
          format.json { render :json => @contributions, status: :ok}
        end
      end
    rescue => e
      render json:{
        error: e.message,
        status: :unprocessable_entity
      }, status: :unprocessable_entity
    end
  end


  private
  # Use callbacks to share common setup or constraints between actions.
  def set_contribution
    begin
      @contribution = Contribution.find(params[:id])
    rescue => e
      @contribution = nil
    end
  end

  # Only allow a list of trusted parameters through.
  def contribution_params
    params.require(:contribution).permit(:contribution_type, :text, :title, :url)
  end

  def check_signed_in
    if !user_signed_in?
      head :unprocessable_entity
      return
    end
  end

  def get_user_from_token
    begin
      header = request.headers['Authorization'].split(' ').last
      auth_token = JWT.decode header, "secreto", true, { verify_iat: true, algorithm: 'HS256' }
      user_id = auth_token[0]["user_id"]
      @user = User.find(user_id)
    rescue => e
      @user = nil
    end
  end
end
