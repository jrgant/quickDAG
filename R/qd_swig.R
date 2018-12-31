#' Generate a single word intervention graph (SWIG) template
#'
#' @description
#' Provide simple syntax specifying paths between nodes to generate a graph object.
#'
#' @param graph.obj A DAG object created by \code{qd_dag()}.
#' @param fixed.nodes A vector containing the nodes to be intervened upon.
#'
#' Suggestions and bug reports welcome at \url{https://github.com/jrgant/quickDAG/issues}.
#'
#'
#' Packages used: DiagrammeR, stringr, purrr
#'
#' @examples
#' # Provide a DAG object and a list of nodes to be fixed
#' qd_swig(dag, c("A", "L")) %>% render_graph()
#'
#' @export qd_swig
#' @import DiagrammeR
#' @importFrom dplyr data_frame
#' @importFrom dplyr bind_rows
#' @importFrom dplyr mutate

qd_swig <- function(graph.obj, fixed.nodes) {

  # identify relations between parents and children
  rel.l <- lapply(fixed.nodes, FUN = function(x) {
    pt.id <- get_node_ids(graph.obj, conditions = alpha.id == x)
    ch.id <- get_successors(graph.obj, node = pt.id)

    df <- dplyr::data_frame(pt.id, pt.alpha = x, ch.id)
  })

  rel.df <- dplyr::bind_rows(rel.l)

  # create label insert based on child's fixed parents
  unq.ch <- unique(rel.df$ch.id)
  slug.l <- lapply(unq.ch, FUN = function(x) {
    curr.ch <- x
    lab.slug <- with(rel.df,
                     paste(tolower(pt.alpha[ch.id == x]), collapse = ","))
    df <- dplyr::data_frame(ch.id = curr.ch, lab.slug)
  })

  slug.df <- dplyr::bind_rows(slug.l)

  # update child label in node_df
  graph.obj$nodes_df <-
    graph.obj %>%
    get_node_df() %>%
    dplyr::mutate(
      label = ifelse(id %in% slug.df$ch.id,
                     paste0(alpha.id, "@^{<i>", na.omit(slug.df$lab.slug[match(id, slug.df$ch.id)]), "</i>}"),
                     label),
      label = ifelse(id %in% rel.df$pt.id,
                     paste(label, "|", tolower(alpha.id)),
                     label),
      fixed = ifelse(id %in% rel.df$pt.id, TRUE, FALSE))

  return(graph.obj)

}





