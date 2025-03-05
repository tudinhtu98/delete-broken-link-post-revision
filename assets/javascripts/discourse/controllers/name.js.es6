import Controller from "@ember/controller";
import discourseComputed, { on } from "discourse-common/utils/decorators";

export default Controller.extend({
    @on("init")
    reset() {
        this.setProperties({ });
    },

    actions: {
        //function using in /templates/name.hbs
    }
});