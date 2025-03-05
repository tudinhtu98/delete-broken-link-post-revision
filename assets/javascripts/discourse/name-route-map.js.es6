/**
 * Links the path `/name` to a route named `name`. Named like this, a
 * route with the same name needs to be created in the `routes` directory.
 */

export default function () {
    this.route('name', { path: '/name' })
}