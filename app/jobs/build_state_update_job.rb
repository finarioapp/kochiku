class BuildStateUpdateJob < JobBase
  @queue = :high

  def initialize(build_id)
    @build_id = build_id
  end

  def perform
    build = Build.find(@build_id)
    build.update_state_from_parts!
    Rails.logger.info("Build #{build.id} state is now #{build.state}")

    if build.project.main_build? && build.completed?
      sha = GitRepo.current_master_ref(build.repository)
      build.project.builds.create_new_ci_build_for(sha)
    end

    if build.promotable?
      GitRepo.inside_repo(build.repository) do
        build.promote!
      end
    elsif build.auto_merge_enabled?
      if build.auto_mergable?
        GitRepo.inside_repo(build.repository) do
          build.auto_merge!
        end
      else
        Rails.logger.info("Build #{build.id} is auto_merge enabled but cannot be auto merged.")
      end
    end
  end
end
