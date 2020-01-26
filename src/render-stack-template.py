import jinja2

loader = jinja2.FileSystemLoader(searchpath="templates/")
environment = jinja2.Environment(loader=loader)

template = environment.get_template("stack.yml.j2")
result = template.render()
with open("stack.yml", "w+") as fp:
    fp.write(result)
    fp.write("\n")
