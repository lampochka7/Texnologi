import logging
from sqlalchemy import create_engine, Column, Integer, String, ForeignKey
from sqlalchemy.orm import declarative_base, sessionmaker, relationship, joinedload, selectinload
from sqlalchemy import inspect

# Настройка логирования SQLAlchemy для анализа запросов
logging.basicConfig()
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

# Подключение к базе данных
engine = create_engine('sqlite:///./test.db', echo=False)
Session = sessionmaker(bind=engine)
session = Session()

# Определение моделей
Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(50), nullable=False)
    
    # Связь с постами
    posts = relationship("Post", back_populates="author", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User(id={self.id}, name='{self.name}')>"

class Post(Base):
    __tablename__ = 'posts'
    
    id = Column(Integer, primary_key=True)
    title = Column(String(100), nullable=False)
    user_id = Column(Integer, ForeignKey('users.id', ondelete="CASCADE"))
    
    author = relationship("User", back_populates="posts")
    
    def __repr__(self):
        return f"<Post(id={self.id}, title='{self.title}', user_id={self.user_id})>"

# Создание таблиц
Base.metadata.create_all(engine)

print("=" * 60)
print("ЧАСТЬ 1: CRUD-операции")
print("=" * 60)

# Очистка таблиц перед выполнением
session.query(Post).delete()
session.query(User).delete()
session.commit()

# 1. Создание 3 пользователей
print("\n1. Создание пользователей...")
user1 = User(name="Анна")
user2 = User(name="Борис")
user3 = User(name="Виктория")

session.add_all([user1, user2, user3])
session.commit()
print(f"✓ Создано пользователей: {session.query(User).count()}")

# 2. Для каждого пользователя создание по 2 поста
print("\n2. Создание постов...")
posts = [
    Post(title="Первый пост Анны", author=user1),
    Post(title="Второй пост Анны", author=user1),
    Post(title="Борис о программировании", author=user2),
    Post(title="Борис о жизни", author=user2),
    Post(title="Виктория: дневник", author=user3),
    Post(title="Виктория: стихи", author=user3)
]
session.add_all(posts)
session.commit()
print(f"✓ Создано постов: {session.query(Post).count()}")

# 3. Получение пользователя по ID
print("\n3. Получение пользователя по ID...")
user = session.get(User, 1)
print(f"✓ Найден пользователь: {user.name}")

# 4. Изменение имени пользователя
print("\n4. Изменение имени пользователя...")
user.name = "Анна Петрова"
session.commit()
print(f"✓ Имя изменено на: {user.name}")

# 5. Удаление пользователя
print("\n5. Удаление пользователя...")
user_to_delete = session.get(User, 2)
if user_to_delete:
    session.delete(user_to_delete)
    session.commit()
    print(f"✓ Пользователь {user_to_delete.name} удален")
    print(f"  Осталось пользователей: {session.query(User).count()}")
    print(f"  Постов осталось: {session.query(Post).count()}")

print("\n" + "=" * 60)
print("ЧАСТЬ 2: Работа со связями")
print("=" * 60)

# Получение списка всех пользователей и их постов
print("\nПолучение списка пользователей и их постов:")
users = session.query(User).all()

for user in users:
    print(f"\n📱 Пользователь: {user.name}")
    for post in user.posts:
        print(f"   ✏️ Пост: {post.title}")

print("\n" + "=" * 60)
print("ЧАСТЬ 3: Анализ работы ORM")
print("=" * 60)

print("""
Ответы на вопросы:
1. Сколько SQL-запросов выполняется?
   - Выполняется 3 запроса (при наличии 2 пользователей в базе)

2. Почему выполняется именно столько?
   - 1 запрос на получение всех пользователей: SELECT * FROM users
   - 2 запроса на получение постов: по одному на каждого пользователя
     SELECT * FROM posts WHERE user_id = 1
     SELECT * FROM posts WHERE user_id = 3
   
   Это классическая проблема N+1, где N = количество пользователей.
""")

print("\n" + "=" * 60)
print("ЧАСТЬ 4: Проблема N+1")
print("=" * 60)

print("""
1. Определите, возникает ли проблема N+1?
   ДА, возникает.

2. Объясните, в чём её суть:
   Проблема N+1 заключается в том, что ORM выполняет:
   - 1 запрос для получения всех родительских объектов (пользователей)
   - N запросов для получения связанных данных (постов) для каждого объекта
   
   Если у нас 100 пользователей, будет выполнено 101 запрос к базе данных,
   что существенно снижает производительность.
   
   В нашем случае:
   - Пользователей осталось 2
   - Запросов: 1 (на пользователей) + 2 (на посты) = 3 запроса
   
   Проблема возникает при обращении к user.posts внутри цикла,
   так как данные не были предварительно загружены.
""")

print("\n" + "=" * 60)
print("ЧАСТЬ 5: Оптимизация (Eager Loading)")
print("=" * 60)

print("\nДо оптимизации (ленивая загрузка):")
print("Запросов: 1 (пользователи) + N (посты для каждого пользователя)")

print("\nПосле оптимизации (жадная загрузка):")
print("Выполняем запрос с JOIN...")

# Оптимизированный код с eager loading
print("\n--- Результат оптимизации ---")
optimized_users = session.query(User).options(joinedload(User.posts)).all()

for user in optimized_users:
    print(f"\n📱 Пользователь: {user.name}")
    # При обращении к постам новый запрос не выполняется
    for post in user.posts:
        print(f"   ✏️ Пост: {post.title}")

print("""
Сравнение количества SQL-запросов:
┌──────────────────────────────────────────────────────┐
│ До оптимизации: 3 запроса                           │
│ - 1 запрос: SELECT * FROM users                     │
│ - 2 запроса: SELECT * FROM posts WHERE user_id = ?  │
├──────────────────────────────────────────────────────┤
│ После оптимизации: 1 запрос                         │
│ - 1 запрос с JOIN:                                  │
│   SELECT users.*, posts.*                           │
│   FROM users LEFT OUTER JOIN posts                  │
│   ON users.id = posts.user_id                       │
└──────────────────────────────────────────────────────┘

Выигрыш в производительности: в 3 раза меньше запросов.
При большем количестве пользователей выигрыш еще значительнее!
""")

print("\n" + "=" * 60)
print("КОНТРОЛЬНЫЕ ВОПРОСЫ")
print("=" * 60)

print("""
1. Что такое ORM?
   ORM (Object-Relational Mapping) — это технология, позволяющая работать 
   с реляционными базами данных через объектно-ориентированный подход.
   Каждая таблица в БД соответствует классу, а строки — объектам этого класса.

2. Какие преимущества он даёт?
   ✓ Автоматическая генерация SQL-запросов
   ✓ Безопасность (защита от SQL-инъекций)
   ✓ Удобную работу со связями между таблицами
   ✓ Независимость от конкретной СУБД
   ✓ Ускорение разработки

3. В чём заключается проблема N+1?
   Проблема возникает при загрузке связанных данных в цикле:
   - Сначала выполняется 1 запрос для получения всех родительских объектов
   - Затем для каждого объекта выполняется дополнительный запрос
   - Итого: 1 + N запросов, что неэффективно при большом N

4. Когда ORM использовать не стоит?
   ✗ В сложных аналитических запросах с большим количеством JOIN
   ✗ При необходимости тонкой оптимизации производительности
   ✗ Для массовых операций (bulk insert/update) с миллионами записей
   ✗ Если требуется использовать специфические функции конкретной СУБД
""")

print("\n" + "=" * 60)
print("ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ")
print("=" * 60)

print("""
Реализация выборки с использованием JOIN:
""")

# Пример с явным JOIN
from sqlalchemy.orm import aliased

print("\n--- Пример с JOIN (явное объединение) ---")
result = session.query(User, Post).join(Post, User.id == Post.user_id).all()

for user, post in result:
    print(f"👤 {user.name} → 📝 {post.title}")

print("""
Сравнение производительности ORM и чистого SQL:
┌────────────────────────────────────────────────────────────┐
│ ORM (с оптимизацией):                                     │
│   - Код: 2-3 строки                                        │
│   - Запросов: 1 (с JOIN)                                   │
│   - Удобство: высокое                                      │
├────────────────────────────────────────────────────────────┤
│ Чистый SQL:                                                │
│   - Код: 1 строка SQL + обработка результатов              │
│   - Запросов: 1                                            │
│   - Удобство: низкое (нет автоматического маппинга)       │
│   - Производительность: максимальная                       │
└────────────────────────────────────────────────────────────┘

Вывод: ORM удобен для разработки, но требует понимания
генерируемых запросов для предотвращения проблем с производительностью.
""")

print("\n" + "=" * 60)
print("ИТОГИ")
print("=" * 60)

print("""
✓ Выполнены CRUD-операции через ORM
✓ Реализована работа со связями между сущностями
✓ Проанализированы выполняемые SQL-запросы
✓ Выявлена и исправлена проблема N+1
✓ Проведена оптимизация с использованием eager loading

ORM значительно упрощает работу с базой данных,
но требует понимания того, что происходит «под капотом»
для написания эффективного кода.
""")

# Закрытие сессии
session.close()
