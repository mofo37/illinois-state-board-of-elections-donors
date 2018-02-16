class SpreadsheetsController < ApplicationController
  before_action :set_spreadsheet, only: [:show, :edit, :update, :destroy]

  # GET /spreadsheets
  def index
    @spreadsheets = Spreadsheet.all.to_a
    @latest_spreadsheet = @spreadsheets.shift
  end

  # GET /spreadsheets/1
  def show
  end

  # GET /spreadsheets/new
  def new
    @spreadsheet = Spreadsheet.new
  end

  # GET /spreadsheets/1/edit
  def edit
  end

  # POST /spreadsheets
  def create
    @spreadsheet = Spreadsheet.new(spreadsheet_params)

    if @spreadsheet.save
      redirect_to @spreadsheet, notice: 'Spreadsheet was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /spreadsheets/1
  def update
    if @spreadsheet.update(spreadsheet_params)
      redirect_to @spreadsheet, notice: 'Spreadsheet was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /spreadsheets/1
  def destroy
    @spreadsheet.destroy
    redirect_to spreadsheets_url, notice: 'Spreadsheet was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spreadsheet
      @spreadsheet = Spreadsheet.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def spreadsheet_params
      params.require(:spreadsheet).permit(:url)
    end
end
