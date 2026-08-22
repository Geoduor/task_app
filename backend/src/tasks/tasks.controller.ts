import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { TasksService } from './tasks.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { TaskResponseDto } from './dto/task-response.dto';

@Controller('tasks')
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  // POST /tasks  { "title": "Buy milk" }  -> 201 Created
  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() createTaskDto: CreateTaskDto): Promise<TaskResponseDto> {
    return this.tasksService.create(createTaskDto);
  }

  // GET /tasks -> 200 OK
  // Not required by the brief, but the mobile screen needs a way to list
  // tasks it didn't create in-memory (e.g. after a restart).
  @Get()
  findAll(): Promise<TaskResponseDto[]> {
    return this.tasksService.findAll();
  }

  // PATCH /tasks/:id/complete -> 200 OK
  @Patch(':id/complete')
  @HttpCode(HttpStatus.OK)
  complete(@Param('id') id: string): Promise<TaskResponseDto> {
    return this.tasksService.complete(id);
  }
}
