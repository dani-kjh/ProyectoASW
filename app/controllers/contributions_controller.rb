class ContributionsController < ApplicationController
  before_action :set_contribution, only: [:show, :edit, :update, :destroy]

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
    @contributions = Contribution.all.order('created_at DESC') 
  end

  def show_news
    @contributions = Contribution.all.order(created_at: :desc)
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

    #TODO: change this to redirect if user is not logged in
    ################################################################
    if user_signed_in? 
      user_id = current_user.id 
    else
      user_id = 1
    end
    ################################################################
    
    @contribution = ContributionServices::CreateContributionService.new(contribution_params, user_id).call

    respond_to do |format|
      if @contribution.save
        format.html { redirect_to show_news_contributions_url }
        format.json { render :show, status: :created, location: @contribution }
      else
        format.html { redirect_to new_contribution_path, alert: @contribution.errors.full_messages.join(', ') }
        format.json { render json: @contribution.errors, status: :unprocessable_entity }
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_contribution
      @contribution = Contribution.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def contribution_params
      params.require(:contribution).permit(:contribution_type, :text, :title, :url)
    end
end