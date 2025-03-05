# name: delete-broken-link-post-revision
# about: Find and delete broken link post revision
# version: 1.0.0
# authors: Tu Dinh Tu
# url:

enabled_site_setting :delete_broken_link_post_revision_enable

register_asset 'stylesheets/delete_broken_link_post_revision.scss'

after_initialize do
    [
        '../app/controllers/delete_broken_link_post_revision_controller.rb',
        '../app/jobs/scheduled/cleanup_broken_links.rb',
    ].each { |path| load File.expand_path(path, __FILE__) }

    Discourse::Application.routes.append do
        # Map the path `/name` to `DeleteBrokenLinkPostRevisionController`’s `index` method
        # Remove route if not in use
        # get '/name' => 'name#index'
    end
end