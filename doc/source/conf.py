def setup(app):
    app.add_css_file('css/custom.css')


extensions = [
  'sphinx.ext.todo',
  'sphinx_fontawesome',
  'sphinxcontrib.blockdiag',
  'sphinxcontrib.nwdiag'
]
source_suffix = '.rst'
master_doc = 'index'
project = u'OSISM Testbed'
copyright = u'2019-2023, OSISM GmbH'
author = u'OSISM GmbH'
version = u''
release = u''
language = 'en'
exclude_patterns = []
pygments_style = 'sphinx'
todo_include_todos = True
html_theme = 'sphinx_material'
html_show_sphinx = False
html_show_sourcelink = False
html_show_copyright = True
htmlhelp_basename = 'documentation'
html_theme_options = {
    "nav_title": "OSISM Documentation",
    "color_primary": "blue",
    "color_accent": "light-blue",
    "globaltoc_depth": 3,
    "globaltoc_collapse": True,
}
html_logo = 'images/logo.png'
html_static_path = [
    '_static'
]
html_title = "OSISM Documentation"
html_sidebars = {
    "**": ["logo-text.html", "globaltoc.html", "localtoc.html", "searchbox.html"]
}
latex_elements = {}
