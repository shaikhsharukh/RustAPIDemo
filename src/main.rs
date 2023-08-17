use std::net::SocketAddr;
use axum::{
    routing::{get,post},Router,
    extract::{State, Path},
    Json, Form,// Router,
};
use axum_error::Result;
use sqlx::sqlite::SqlitePool;
use tower_http::cors::CorsLayer;
use serde::{Serialize, Deserialize};
use tower_http::trace::{self, TraceLayer};
use tracing::Level;

#[tokio::main]
async fn main() -> Result<()>{
    //get enviornment variable
    let _ = dotenv::dotenv();
    let url = std::env::var("DATABASE_URL")?;

    let pool = SqlitePool::connect(&url).await?;

    tracing_subscriber::fmt()
        .with_target(false)
        .compact()
        .init();

    let app = Router::new()
    .route("/",get(list))
    .route("/gets/:id",get(gets))
    .route("/create",post(create))
    .route("/update",post(update))
    .route("/delete/:id", get(delete))
    .with_state(pool)
    .layer(CorsLayer::very_permissive())
    .layer(
        TraceLayer::new_for_http()
            .make_span_with(trace::DefaultMakeSpan::new()
                .level(Level::INFO))
            .on_response(trace::DefaultOnResponse::new()
                .level(Level::INFO)),
    );

    let address = SocketAddr::from(([0,0,0,0],8000)); 
    tracing::info!("listening on {}", address);
    Ok(axum::Server::bind(&address)
    .serve(app.into_make_service()) 
    .await.unwrap())
}

#[derive(Serialize,Deserialize)]
struct Todo {
    #[serde(skip_deserializing)]
    id:i64,
    description:String,
    done:bool
}

async fn list(State(pool):State<SqlitePool>)-> Result<Json<Vec<Todo>>>{
    let todos = sqlx::query_as!(Todo," select id,description,done from todos order by id").fetch_all(&pool).await?;
    Ok(Json(todos))
}

async fn create(State(pool):State<SqlitePool>,Form(todo):Form<Todo>)-> Result<String>{
    sqlx::query!("insert into todos (description) values (?)",todo.description).execute(&pool).await?;
    Ok(format!("Successfully insert todo!"))
}

async fn delete(State(pool):State<SqlitePool>,Path(id):Path<i64>)-> Result<String>{
    sqlx::query!("delete from todos where id=?",id).execute(&pool).await?;
    Ok(format!("Successfully Deleted todo!"))
}
async fn gets(State(pool):State<SqlitePool>,Path(id):Path<i64>)-> Result<Json<Todo>>{
    let todos = sqlx::query_as!(Todo," select * from todos where id=?",id).fetch_one(&pool).await?;
    Ok(Json(todos))
}

async fn update(State(pool):State<SqlitePool>,Form(todo):Form<Todo>)-> Result<String>{
    tracing::info!("{}", todo.done);
    
    sqlx::query!("update todos set description=?,done=? where id=?",todo.description,todo.done,todo.id).execute(&pool).await?;
    Ok(format!("Successfully updated todo!"))
}