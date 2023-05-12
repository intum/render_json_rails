# RenderJsonRails

RenderJsonRails pozwala w łatwy sposób dodać możliwość renderowania JSON z ActiveRecord-ów z zależnościami (has_many itp).
Dzięki temu łatwo jest stworzyć backend Json API np. do pracy z Reactem lub Vue.js

## Przykład

```ruby

class Team < ActiveRecord::Base
  has_many :users

  include RenderJsonRails::Concern

  render_json_config name: :team,
                     includes: {
                       users: User
                     }
end

class User < ActiveRecord::Base
  belongs_to :team

  include RenderJsonRails::Concern

  render_json_config name: :user,
                     except: [:account_id, :id],
                     # only: [:login, :email], # jesli wolelibyśmy wymienić pola zamiast je wykluczać przy pomocy "except"
                     default_fields: [:login, :email, :calculated_age],
                     allowed_methods: [:calculated_age],
                     includes: {
                       team: Team
                     }

  def calculated_age
    rand(100)
  end
end
```

Dodajemy też w kontrolerze ```teams_controller.rb```

```ruby
  include RenderJsonRails::Helper

  def index
    @team = Team.all
    respond_to do |format|
      format.html
      format.json { render_json @team }
    end
  end
```

i możemy już otrzymać JSON team-u wraz z userami

```html
http://example.test/teams/1.json?include=users
```

możemy też określić jakie pola mają być w json

```html
http://example.test/teams/1.json?fields[team]=name,description
```

i możemy łączyć to z include

```html
http://example.test/teams/1.json?fields[team]=name,description&fields[user]=email,name&include=users
```

include mogą być zagnieżdżane (po kropce)

```html
http://example.test/teams/1.json?fields[team]=name,description&fields[user]=email,name&fields[role]=name&include=users,users.roles
```

### Additional Fields

aby wyświetlić domyślne pola oraz np. dodatkowe metody używamy `additional_fields` (dzięki temu nie trzeba wypisywać wszystkich domyślnych pól, gdy chcemy wyświetlić dodatkową jakąś metodę z `allowed_methods`)

```html
http://example.test/teams/1.json?additional_fields[user]=calculate_age # wyświetli wszystkie pole usera oraz dodatkowo `calculate_age`
```


## Wiecej przykładów użycia

`http://example.test/data/9.json?formatted=yes&include=positions,positions.correction_before,positions.correction_after,department,invoice,invoices,invoice.positions&fields[invoice]=id,invoice_id,positions&fields[department]=name,id&fields[invoice_position]=id,name,tax`

Więcej przykładów jest w testach: [test/render_json_rails_test.rb](test/render_json_rails_test.rb)



## Wszystkie opcje ```render_json_config```

```ruby
render_json_config name: :team,
  except: [:account_id, :config], # tych pól nie będzie w json-ie
  only: [:id, :name], # dozwolone pola będą w jsonie (wymiennie z except)
  methods: [:image], # dozwolone i domyślnie wyświetlone metody, ten parametr warto uzywac tylko, gdy nie ma parametru "default_fields" - przy ustawionym "default_fields" trzeba metody wymienic w allowed_methods
  default_fields: [:id, :name, :members], # domyślnie wyświetlone pola + metody
  allowed_methods: [:members], # dozwolone metody, mogą być dodane przez parametr fileds np: fields[team]=id,members
  includes: { # to mozna dołączać za pomoca parametru include np include=users,category,users.roles
   users: Users,
   category: Category
  }
```
Domyślnie wszystkie pola klasy są udostępniane. W kodzie możemy dodać jeden z parametrów:\
except - lista pól które NIE zostaną wyświetlone w jsonie, wszystkie pozostałe pola będą widoczne\
only - lista pól które zosataną wyświetlone, wszystkie pozostałe pola bedą ukryte\
Domyślnie metody nie są wyświetlane i nie są dostępne przez api (dozwolone). Można to zmienić używając ponizszych parametrów:\
methods - lista metod które bedą domyślnie wyświetlane (i dozwolone)
allowed_methods - lista metod które są dozwolone, czyli możemy je wyświetlić korzystająć z additional_fields




## Installation

Add this line to your application's Gemfile:

```ruby
gem 'render_json_rails'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install render_json_rails

## Tests

```
rake test
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/intum/render_json_rails.

