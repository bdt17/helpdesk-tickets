class ProjectsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @projects = Project.all
  end
  
  def new
    @project = Project.new
  end
  
  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to projects_path, notice: "Project created!"
    else
      render :new
    end
  end
  
  private
  def project_params
    params.require(:project).permit(:category, :equipment, :priority, :status)
  end
end
