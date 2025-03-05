import { withPluginApi } from "discourse/lib/plugin-api";
import { helperContext } from "discourse-common/lib/helpers";

export default {
    name: "initializer-name",
    initialize() {
        withPluginApi("0.11.0", api => {
            //get all settings for site
            const siteSettings = helperContext().siteSettings;
            //doing something
        });
    }
}
